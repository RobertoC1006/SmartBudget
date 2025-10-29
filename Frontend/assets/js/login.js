document.addEventListener("DOMContentLoaded", () => {
    if (!window.SB) return;
    const { renderUserBadge, renderNavigation, showAlert, request, storage, fetchCurrentUser } = window.SB;

    renderNavigation("[data-nav-list]");
    renderUserBadge("[data-user-badge]");

    const form = document.getElementById("loginForm");
    const alertContainer = document.getElementById("alertContainer");

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        const email = form.email.value.trim();
        const password = form.password.value.trim();

        if (!email || !password) {
            showAlert(alertContainer, "Completa todos los campos.", "warning");
            return;
        }

        form.querySelector("button[type='submit']").disabled = true;

        try {
            const tokens = await request("/auth/login", {
                method: "POST",
                body: { email, password },
                auth: false,
            });
            storage.setTokens({
                accessToken: tokens.access_token,
                refreshToken: tokens.refresh_token,
            });
            await fetchCurrentUser();
            showAlert(alertContainer, "Inicio de sesión exitoso. Redireccionando...", "success");
            setTimeout(() => {
                window.location.replace("dashboard.html");
            }, 800);
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible iniciar sesión.", "danger");
        } finally {
            form.querySelector("button[type='submit']").disabled = false;
        }
    });
});
