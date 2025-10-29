document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, request, utils, showAlert, storage } = window.SB;

    const alertContainer = document.getElementById("alertContainer");
    const details = document.getElementById("currentBudgetDetails");
    const form = document.getElementById("budgetForm");

    try {
        const user = await initProtectedPage();
        if (user) {
            document.getElementById(
                "budgetSubheading"
            ).textContent = `Organiza tu presupuesto en ${user.default_currency || "PEN"} y recibe alertas personalizadas.`;
        }
        await loadBudget();
    } catch (error) {
        showAlert(alertContainer, error.message || "No se pudo cargar el presupuesto.", "danger");
    }

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        const payload = {
            amount: Number(form.amount.value),
            month: form.month.value ? Number(form.month.value) : undefined,
            year: form.year.value ? Number(form.year.value) : undefined,
            name: form.name.value.trim() || undefined,
            alert_threshold: form.alert_threshold.value ? Number(form.alert_threshold.value) : undefined,
        };

        if (!payload.amount || payload.amount <= 0) {
            showAlert(alertContainer, "Ingresa un monto válido.", "warning");
            return;
        }

        form.querySelector("button").disabled = true;

        try {
            await request("/budgets/", { method: "POST", body: payload });
            showAlert(alertContainer, "Presupuesto actualizado exitosamente.", "success");
            form.reset();
            await loadBudget();
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible actualizar el presupuesto.", "danger");
        } finally {
            form.querySelector("button").disabled = false;
        }
    });

    async function loadBudget() {
        try {
            const budget = await request("/budgets/current");
            const currency = budget.currency || storage.getUser()?.default_currency || "PEN";
            details.innerHTML = `
                <dt class="col-5 text-secondary">Nombre</dt>
                <dd class="col-7 text-sb-dark">${budget.name}</dd>
                <dt class="col-5 text-secondary">Período</dt>
                <dd class="col-7 text-sb-dark">${budget.month}/${budget.year}</dd>
                <dt class="col-5 text-secondary">Monto</dt>
                <dd class="col-7 text-sb-dark">${utils.formatCurrency(budget.amount, currency)}</dd>
                <dt class="col-5 text-secondary">Gastado</dt>
                <dd class="col-7 text-sb-dark">${utils.formatCurrency(budget.spent, currency)}</dd>
                <dt class="col-5 text-secondary">Disponible</dt>
                <dd class="col-7 text-success fw-semibold">${utils.formatCurrency(budget.remaining, currency)}</dd>
                <dt class="col-5 text-secondary">Umbral alerta</dt>
                <dd class="col-7 text-sb-dark">${(budget.alert_threshold * 100).toFixed(0)}%</dd>
                <dt class="col-5 text-secondary">Actualizado</dt>
                <dd class="col-7 text-muted">${utils.formatDate(budget.updated_at)}</dd>
            `;
        } catch (error) {
            details.innerHTML = `
                <dt class="col-5 text-secondary">Estado</dt>
                <dd class="col-7 text-sb-dark">Sin presupuesto activo</dd>
            `;
            console.info("Budget", error.message);
        }
    }
});
