const SB = (() => {
    const RUNTIME_CONFIG = window.__SB_RUNTIME_CONFIG__ || window.SB_RUNTIME_CONFIG || {};
    const API_BASE_URL = RUNTIME_CONFIG.apiBaseUrl || RUNTIME_CONFIG.API_BASE_URL || "http://127.0.0.1:8000/api";
    const OCR_WEBHOOK_URL = RUNTIME_CONFIG.ocrWebhookUrl || RUNTIME_CONFIG.OCR_WEBHOOK_URL || null;
    const ACCESS_TOKEN_KEY = "sb_access_token";
    const REFRESH_TOKEN_KEY = "sb_refresh_token";
    const USER_KEY = "sb_user";

    const storage = {
        setTokens({ accessToken, refreshToken }) {
            localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
            localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
        },
        clearTokens() {
            localStorage.removeItem(ACCESS_TOKEN_KEY);
            localStorage.removeItem(REFRESH_TOKEN_KEY);
        },
        getAccessToken() {
            return localStorage.getItem(ACCESS_TOKEN_KEY);
        },
        getRefreshToken() {
            return localStorage.getItem(REFRESH_TOKEN_KEY);
        },
        setUser(user) {
            localStorage.setItem(USER_KEY, JSON.stringify(user));
        },
        getUser() {
            const raw = localStorage.getItem(USER_KEY);
            if (!raw) return null;
            try {
                return JSON.parse(raw);
            } catch (error) {
                console.warn("No fue posible parsear el usuario guardado", error);
                return null;
            }
        },
        clearUser() {
            localStorage.removeItem(USER_KEY);
        },
    };

    async function request(path, { method = "GET", body, auth = true, headers = {}, isFormData = false } = {}) {
        const finalHeaders = { ...headers };
        const options = { method };

        if (auth) {
            const token = storage.getAccessToken();
            if (!token) {
                throw new Error("Acceso no autorizado. Inicia sesión nuevamente.");
            }
            finalHeaders.Authorization = `Bearer ${token}`;
        }

        if (body) {
            if (isFormData) {
                options.body = body;
            } else {
                finalHeaders["Content-Type"] = "application/json";
                options.body = JSON.stringify(body);
            }
        }

        options.headers = finalHeaders;

        const response = await fetch(`${API_BASE_URL}${path}`, options);

        if (response.status === 204) {
            return null;
        }

        let data;
        const contentType = response.headers.get("content-type");
        if (contentType && contentType.includes("application/json")) {
            data = await response.json();
        } else {
            data = await response.text();
        }

        if (!response.ok) {
            const message = typeof data === "string" ? data : data?.detail || "Error inesperado";
            throw new Error(message);
        }

        return data;
    }

    function resolvePath(path) {
        const target = path || "/pages/login.html";
        try {
            return new URL(target, window.location.origin).href;
        } catch (error) {
            return target;
        }
    }

    function showAlert(container, message, type = "success") {
        const target = typeof container === "string" ? document.querySelector(container) : container;
        if (!target) return;
        target.innerHTML = `
            <div class="alert alert-${type} alert-dismissible fade show" role="alert">
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
            </div>
        `;
    }

    function requireAuth(redirect = "/pages/login.html") {
        if (!storage.getAccessToken()) {
            window.location.replace(resolvePath(redirect));
        }
    }

    function logout(redirect = "/pages/login.html") {
        storage.clearTokens();
        storage.clearUser();
        window.location.replace(resolvePath(redirect));
    }

    async function fetchCurrentUser() {
        try {
            const user = await request("/auth/me");
            storage.setUser(user);
            renderNavigation();
            renderUserBadge("[data-user-badge]");
            return user;
        } catch (error) {
            logout("/pages/login.html");
            return null;
        }
    }

    function renderUserBadge(selector = "[data-user-badge]") {
        const element = document.querySelector(selector);
        if (!element) return;
        const user = storage.getUser();
        if (user) {
            element.innerHTML = `
                <div class="d-flex align-items-center gap-2">
                    <span class="badge bg-success-subtle text-success px-3 py-2">${user.full_name}</span>
                    <button class="btn btn-outline-success btn-sm" data-action="logout">Cerrar sesión</button>
                </div>
            `;
            element.querySelector("[data-action='logout']").addEventListener("click", () => logout());
        } else {
            element.innerHTML = "";
        }
    }

    function renderNavigation(selector = "[data-nav-list]") {
        const navList = document.querySelector(selector);
        if (!navList) return;
        const isAuthenticated = Boolean(storage.getAccessToken());
        const pathname = window.location.pathname;

        const publicNav = [
            { href: "/index.html#inicio", label: "Inicio", match: "index.html" },
            { href: "/pages/register.html", label: "Registrarse", match: "register.html" },
            { href: "/pages/login.html", label: "Iniciar sesión", match: "login.html" },
        ];

        const privateNav = [
            { href: "/pages/dashboard.html", label: "Dashboard", match: "dashboard.html" },
            { href: "/pages/budget.html", label: "Presupuesto", match: "budget.html" },
            { href: "/pages/expenses.html", label: "Gastos", match: "expenses.html" },
            { href: "/pages/smartscore.html", label: "SmartScore", match: "smartscore.html" },
            { href: "/pages/simulator.html", label: "Simulador", match: "simulator.html" },
            { href: "/pages/goals.html", label: "Metas", match: "goals.html" },
            { href: "/pages/profile.html", label: "Perfil", match: "profile.html" },
        ];

        const items = isAuthenticated ? privateNav : publicNav;

        navList.innerHTML = items
            .map((item) => {
                const isActive = item.match
                    ? pathname.endsWith(item.match)
                    : pathname === "/" && item.href.includes("#inicio");
                return `
                    <li class="nav-item">
                        <a class="nav-link${isActive ? " active" : ""}" href="${item.href}">${item.label}</a>
                    </li>
                `;
            })
            .join("");
    }

    async function initProtectedPage(options = {}) {
        const redirect = options.redirect ?? "/pages/login.html";
        requireAuth(redirect);
        let user = storage.getUser();
        if (!user) {
            user = await fetchCurrentUser();
        }
        renderUserBadge("[data-user-badge]");
        renderNavigation();
        return user;
    }

    function formatCurrency(value, currency = "PEN") {
        if (value === null || value === undefined || value === "") return "-";
        const amount = Number(value);
        if (Number.isNaN(amount)) return value;
        const locale = currency === "USD" ? "en-US" : "es-PE";
        return new Intl.NumberFormat(locale, {
            style: "currency",
            currency,
            currencyDisplay: "symbol",
        }).format(amount);
    }

    function formatDate(value) {
        if (!value) return "-";
        const date = new Date(value);
        if (Number.isNaN(date.getTime())) return value;
        return new Intl.DateTimeFormat("es-PE", { year: "numeric", month: "long", day: "numeric" }).format(date);
    }

    return {
        config: {
            API_BASE_URL,
            apiBaseUrl: API_BASE_URL,
            OCR_WEBHOOK_URL,
            ocrWebhookUrl: OCR_WEBHOOK_URL,
            hasOcrWebhook: Boolean(OCR_WEBHOOK_URL),
        },
        storage,
        request,
        showAlert,
        requireAuth,
        logout,
        fetchCurrentUser,
        renderUserBadge,
        renderNavigation,
        initProtectedPage,
        utils: { formatCurrency, formatDate },
    };
})();

window.SB = SB;
