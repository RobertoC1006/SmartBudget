document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, request, showAlert, utils } = window.SB;

    const alertContainer = document.getElementById("alertContainer");
    const recalcBtn = document.getElementById("recalculateBtn");
    const refreshAlertsBtn = document.getElementById("refreshAlertsBtn");

    try {
        await initProtectedPage();
        await Promise.all([loadHistory(), loadAlerts()]);
    } catch (error) {
        showAlert(alertContainer, error.message || "No se pudo cargar el SmartScore.", "danger");
    }

    recalcBtn.addEventListener("click", async () => {
        recalcBtn.disabled = true;
        showAlert(alertContainer, "Calculando SmartScore...", "info");
        try {
            const snapshot = await request("/smartscore/recalculate", { method: "POST" });
            showAlert(alertContainer, "SmartScore recalculado correctamente.", "success");
            updateCurrentSnapshot(snapshot);
            await loadAlerts();
            await loadHistory();
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible recalcular el SmartScore.", "danger");
        } finally {
            recalcBtn.disabled = false;
        }
    });

    refreshAlertsBtn.addEventListener("click", loadAlerts);

    async function loadHistory() {
        try {
            const snapshots = await request("/smartscore/history");
            const tbody = document.getElementById("smartscoreHistory");
            if (!snapshots.length) {
                tbody.innerHTML = `<tr><td colspan="4" class="text-center text-secondary py-4">Sin registros.</td></tr>`;
                updateCurrentSnapshot(null);
                return;
            }

            tbody.innerHTML = snapshots
                .map(
                    (snapshot) => `
                        <tr>
                            <td>${utils.formatDate(snapshot.created_at)}</td>
                            <td>${snapshot.score}</td>
                            <td class="text-uppercase">${snapshot.band}</td>
                            <td>${snapshot.summary}</td>
                        </tr>
                    `
                )
                .join("");

            updateCurrentSnapshot(snapshots[0]);
            renderDrivers(snapshots[0]?.drivers);
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, "No fue posible obtener el histórico.", "warning");
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
                        <div class="alert alert-${mapSeverity(alert.severity)}">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <div class="fw-semibold">${alert.title}</div>
                                    <div class="small">${alert.message}</div>
                                    <div class="text-muted small">${utils.formatDate(alert.created_at)}</div>
                                </div>
                            </div>
                        </div>
                    `
                )
                .join("");
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, "No fue posible cargar las alertas.", "warning");
        }
    }

    function updateCurrentSnapshot(snapshot) {
        const scoreEl = document.getElementById("currentScore");
        const bandEl = document.getElementById("currentBand");
        const summaryEl = document.getElementById("currentSummary");

        if (!snapshot) {
            scoreEl.textContent = "-";
            bandEl.textContent = "Sin cálculo";
            summaryEl.textContent = "Calcula tu SmartScore para recibir un diagnóstico.";
            return;
        }

        scoreEl.textContent = `${snapshot.score}/100`;
        bandEl.textContent = snapshot.band.toUpperCase();
        bandEl.className = `badge rounded-pill ${bandBadgeClass(snapshot.band)}`;
        summaryEl.textContent = snapshot.summary;
        renderDrivers(snapshot.drivers);
    }

    function renderDrivers(drivers) {
        const container = document.getElementById("driversList");
        if (!drivers) {
            container.innerHTML = `<p class="text-secondary small mb-0">Sin datos disponibles.</p>`;
            return;
        }

        const entries = Object.entries(drivers).filter(([key]) => key !== "category_totals");
        const categoryTotals = drivers.category_totals || {};

        container.innerHTML = `
            <h6 class="text-secondary text-uppercase small">Penalizaciones</h6>
            <ul class="list-group list-group-flush mb-3">
                ${entries
                    .map(
                        ([key, value]) => `
                        <li class="list-group-item bg-transparent d-flex justify-content-between align-items-center">
                            <span class="text-capitalize">${key.replace("_", " ")}</span>
                            <span class="badge text-bg-light text-sb-dark">${value}</span>
                        </li>
                    `
                    )
                    .join("")}
            </ul>
            <h6 class="text-secondary text-uppercase small">Gasto por categoría</h6>
            <ul class="list-group list-group-flush">
                ${Object.entries(categoryTotals)
                    .map(
                        ([category, amount]) => `
                        <li class="list-group-item bg-transparent d-flex justify-content-between align-items-center">
                            <span class="text-capitalize">${category.replace("_", " ")}</span>
                            <span class="badge text-bg-success-subtle text-success">${utils.formatCurrency(amount)}</span>
                        </li>
                    `
                    )
                    .join("")}
            </ul>
        `;
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

    function bandBadgeClass(band) {
        switch (band) {
            case "good":
                return "text-bg-success";
            case "moderate":
                return "text-bg-warning";
            default:
                return "text-bg-danger";
        }
    }
});
