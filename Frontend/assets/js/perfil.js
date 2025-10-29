document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, utils } = window.SB;

    const user = await initProtectedPage();

    const details = document.getElementById("profileDetails");
    if (!details || !user) return;

    details.innerHTML = `
        <dt class="col-5 text-secondary">Nombre</dt>
        <dd class="col-7 text-sb-dark">${user.full_name}</dd>
        <dt class="col-5 text-secondary">Correo</dt>
        <dd class="col-7 text-sb-dark">${user.email}</dd>
        <dt class="col-5 text-secondary">Moneda</dt>
        <dd class="col-7 text-sb-dark">${user.default_currency || "PEN"}</dd>
        <dt class="col-5 text-secondary">Ingreso mensual</dt>
        <dd class="col-7 text-sb-dark">${user.monthly_income ? utils.formatCurrency(user.monthly_income, user.default_currency || "PEN") : "No registrado"}</dd>
        <dt class="col-5 text-secondary">Miembro desde</dt>
        <dd class="col-7 text-sb-dark">${utils.formatDate(user.created_at)}</dd>
        <dt class="col-5 text-secondary">Estado</dt>
        <dd class="col-7 text-success fw-semibold">${user.is_active ? "Activo" : "Inactivo"}</dd>
    `;
});

