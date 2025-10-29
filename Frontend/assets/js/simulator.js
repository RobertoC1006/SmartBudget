document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, request, showAlert, utils } = window.SB;

    const alertContainer = document.getElementById("alertContainer");
    const form = document.getElementById("simulatorForm");
    const scenarioSelect = document.getElementById("scenario");
    const customWrapper = document.getElementById("customAdjustmentsWrapper");
    const addCustomBtn = document.getElementById("addCustomAdjustment");
    const customList = document.getElementById("customAdjustmentsList");
    const projectedScore = document.getElementById("projectedScore");
    const projectedBand = document.getElementById("projectedBand");
    const projectedNarrative = document.getElementById("projectedNarrative");
    const projectedBalance = document.getElementById("projectedBalance");
    const projectedAdjustments = document.getElementById("projectedAdjustments");

    const adjustments = new Map();

    try {
        await initProtectedPage();
    } catch (error) {
        showAlert(alertContainer, error.message || "No se pudo cargar el simulador.", "danger");
    }

    scenarioSelect.addEventListener("change", () => {
        const isCustom = scenarioSelect.value === "custom";
        customWrapper.classList.toggle("d-none", !isCustom);
    });

    addCustomBtn.addEventListener("click", () => {
        const category = document.getElementById("customCategory").value;
        const value = Number(document.getElementById("customValue").value);
        if (!category || Number.isNaN(value)) {
            showAlert(alertContainer, "Elige una categoría y porcentaje válido para el ajuste.", "warning");
            return;
        }
        adjustments.set(category, value);
        renderAdjustments();
        document.getElementById("customValue").value = "";
    });

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        const scenario = scenarioSelect.value;
        const percentageInput = form.percentage.value ? Number(form.percentage.value) : undefined;

        if (!scenario) {
            showAlert(alertContainer, "Selecciona un escenario de simulación.", "warning");
            return;
        }
        if (scenario !== "custom" && (percentageInput === undefined || Number.isNaN(percentageInput))) {
            showAlert(alertContainer, "Indica el porcentaje para el escenario seleccionado.", "warning");
            return;
        }
        if (scenario === "custom" && adjustments.size === 0) {
            showAlert(alertContainer, "Agrega al menos un ajuste personalizado.", "warning");
            return;
        }

        const payload = {
            scenario,
            percentage: percentageInput,
            custom_adjustments:
                scenario === "custom"
                    ? Object.fromEntries(Array.from(adjustments.entries()))
                    : undefined,
        };

        form.querySelector("button[type='submit']").disabled = true;
        showAlert(alertContainer, "Ejecutando simulación...", "info");

        try {
            const result = await request("/simulator/", { method: "POST", body: payload });
            showAlert(alertContainer, "Simulación completada correctamente.", "success");
            updateResults(result);
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible ejecutar la simulación.", "danger");
        } finally {
            form.querySelector("button[type='submit']").disabled = false;
        }
    });

    function renderAdjustments() {
        if (!adjustments.size) {
            customList.innerHTML = "";
            return;
        }
        customList.innerHTML = Array.from(adjustments.entries())
            .map(
                ([category, value]) => `
                <li class="list-group-item d-flex justify-content-between align-items-center">
                    <span class="text-capitalize">${category.replace("_", " ")}</span>
                    <span>
                        ${value}% 
                        <button type="button" class="btn btn-link btn-sm text-danger" data-category="${category}">Eliminar</button>
                    </span>
                </li>
            `
            )
            .join("");

        customList.querySelectorAll("button[data-category]").forEach((btn) => {
            btn.addEventListener("click", () => {
                adjustments.delete(btn.dataset.category);
                renderAdjustments();
            });
        });
    }

    function updateResults(result) {
        projectedScore.textContent = `${result.projected_score}/100`;
        projectedBand.textContent = result.band.toUpperCase();
        projectedBand.className = `badge rounded-pill ${bandBadgeClass(result.band)}`;
        projectedNarrative.textContent = result.narrative;
        projectedBalance.textContent = utils.formatCurrency(result.remaining_budget);

        const adjustmentsEntries = Object.entries(result.adjustments || {});
        if (!adjustmentsEntries.length) {
            projectedAdjustments.innerHTML = `<li class="text-secondary">Sin ajustes registrados.</li>`;
        } else {
            projectedAdjustments.innerHTML = adjustmentsEntries
                .map(
                    ([key, amount]) => `
                        <li>
                            <span class="text-capitalize">${key.replace("_", " ")}</span>:
                            <strong>${utils.formatCurrency(amount)}</strong>
                        </li>
                    `
                )
                .join("");
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
