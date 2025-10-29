document.addEventListener("DOMContentLoaded", () => {
    if (!window.SB) return;
    const { renderUserBadge, renderNavigation, showAlert, request } = window.SB;

    renderNavigation("[data-nav-list]");
    renderUserBadge("[data-user-badge]");

    const form = document.getElementById("registerForm");
    const alertContainer = document.getElementById("alertContainer");

    form.addEventListener("submit", async (event) => {
        event.preventDefault();

        const payload = {
            full_name: form.full_name.value.trim(),
            email: form.email.value.trim(),
            password: form.password.value.trim(),
            monthly_income: form.monthly_income.value ? Number(form.monthly_income.value) : undefined,
            default_currency: form.default_currency.value.trim() || undefined,
        };

        if (!payload.full_name || !payload.email || !payload.password) {
            showAlert(alertContainer, "Los campos nombre, correo y contraseña son obligatorios.", "warning");
            return;
        }

        form.querySelector("button[type='submit']").disabled = true;

        try {
            await request("/auth/register", {
                method: "POST",
                body: payload,
                auth: false,
            });
            showAlert(alertContainer, "Registro exitoso. Ahora puedes iniciar sesión.", "success");
            form.reset();
            setTimeout(() => {
                window.location.replace("login.html");
            }, 1200);
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible completar el registro.", "danger");
        } finally {
            form.querySelector("button[type='submit']").disabled = false;
        }
    });
});
