document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, utils, request, showAlert, storage } = window.SB;
    const alertContainer = document.getElementById("alertContainer");

    try {
        await initProtectedPage();
        const user = storage.getUser();
        if (user) {
            document.getElementById("dashboardSubheading").textContent = `Hola, ${user.full_name}. Este es el resumen de tu mes.`;
        }
        await Promise.all([loadBudget(), loadExpenses(), loadSmartScore(), loadAlerts()]);
    } catch (error) {
        console.error(error);
        showAlert(alertContainer, error.message || "No se pudieron cargar los datos.", "danger");
    }

    async function loadBudget() {
        try {
            const budget = await request("/budgets/current");
            document.getElementById("budgetAmount").textContent = utils.formatCurrency(
                budget.amount,
                budget.currency || "PEN"
            );
            document.getElementById("budgetRemaining").textContent = utils.formatCurrency(
                budget.remaining,
                budget.currency || "PEN"
            );
            document.getElementById("budgetSpent").textContent = `Has gastado ${utils.formatCurrency(
                budget.spent,
                budget.currency || "PEN"
            )}`;
            document.getElementById("budgetPeriod").textContent = `${budget.month}/${budget.year} • ${
                budget.name
            }`;
        } catch (error) {
            document.getElementById("budgetAmount").textContent = "-";
            document.getElementById("budgetRemaining").textContent = "-";
            document.getElementById("budgetSpent").textContent = "Define un presupuesto para comenzar.";
            document.getElementById("budgetPeriod").textContent = "Sin presupuesto activo";
            console.info("Budget", error.message);
        }
    }

    async function loadExpenses() {
        try {
            const expenses = await request("/expenses?limit=6");
            const tbody = document.getElementById("expensesTableBody");
            if (!expenses.length) {
                tbody.innerHTML = `<tr><td colspan="4" class="text-center text-secondary py-4">Aún no registras gastos.</td></tr>`;
                return;
            }
            const currency = expenses[0]?.currency || "PEN";
            tbody.innerHTML = expenses
                .map(
                    (expense) => `
                        <tr>
                            <td>${expense.description}</td>
                            <td>${utils.formatDate(expense.expense_date)}</td>
                            <td class="text-capitalize">${expense.category.replace("_", " ")}</td>
                            <td class="text-end">${utils.formatCurrency(expense.amount, currency)}</td>
                        </tr>
                    `
                )
                .join("");
        } catch (error) {
            console.error("Expenses", error);
            showAlert(alertContainer, "No fue posible obtener los gastos recientes.", "warning");
        }
    }

    async function loadSmartScore() {
        try {
            const snapshots = await request("/smartscore/history");
            if (!snapshots.length) {
                document.getElementById("smartscoreValue").textContent = "-";
                document.getElementById("smartscoreBand").textContent = "Sin calcular";
                document.getElementById("smartscoreSummary").textContent =
                    "Genera tu SmartScore desde la sección correspondiente.";
                return;
            }
            const latest = snapshots[0];
            document.getElementById("smartscoreValue").textContent = `${latest.score}/100`;
            document.getElementById("smartscoreBand").textContent = latest.band.toUpperCase();
            document.getElementById("smartscoreSummary").textContent = latest.summary;
        } catch (error) {
            console.error("SmartScore", error);
            document.getElementById("smartscoreSummary").textContent =
                "Calcula el SmartScore para ver tu estado financiero.";
        }
    }

    async function loadAlerts() {
        try {
            const alerts = await request("/alerts");
            const container = document.getElementById("alertsList");
            if (!alerts.length) {
                container.innerHTML = `<div class="alert alert-success mb-0">Sin alertas activas.</div>`;
                return;
            }
            container.innerHTML = alerts
                .map(
                    (alert) => `
                        <div class="alert alert-${mapSeverity(alert.severity)} mb-0">
                            <div class="fw-semibold mb-1">${alert.title}</div>
                            <div class="small">${alert.message}</div>
                            <div class="text-muted small">${utils.formatDate(alert.created_at)}</div>
                        </div>
                    `
                )
                .join("");
        } catch (error) {
            console.error("Alerts", error);
        }
    }

    function mapSeverity(severity) {
        switch (severity) {
            case "critical":
                return "danger";
            case "warning":
                return "warning";
            default:
                return "success";
        }
    }
});
