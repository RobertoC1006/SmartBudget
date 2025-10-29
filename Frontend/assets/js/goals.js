document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, request, showAlert, utils } = window.SB;

    const alertContainer = document.getElementById("alertContainer");
    const suggestionsList = document.getElementById("suggestionsList");
    const goalsTable = document.getElementById("goalsTable");
    const goalForm = document.getElementById("goalForm");
    const goalModalEl = document.getElementById("goalModal");
    const goalModal = goalModalEl ? new bootstrap.Modal(goalModalEl) : null;

    try {
        await initProtectedPage();
        await Promise.all([loadSuggestions(), loadGoals()]);
    } catch (error) {
        showAlert(alertContainer, error.message || "No se pudo cargar la información.", "danger");
    }

    goalForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const payload = {
            name: goalForm.goalName.value.trim(),
            description: goalForm.goalDescription.value.trim() || undefined,
            target_amount: Number(goalForm.goalAmount.value),
            target_date: goalForm.goalDate.value || undefined,
        };

        if (!payload.name || !payload.target_amount) {
            showAlert(alertContainer, "Completa nombre y monto objetivo.", "warning");
            return;
        }

        goalForm.querySelector("button[type='submit']").disabled = true;

        try {
            await request("/goals/", { method: "POST", body: payload });
            showAlert(alertContainer, "Meta creada exitosamente.", "success");
            goalForm.reset();
            goalModal?.hide();
            await loadGoals();
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible registrar la meta.", "danger");
        } finally {
            goalForm.querySelector("button[type='submit']").disabled = false;
        }
    });

    async function loadSuggestions() {
        try {
            const suggestions = await request("/goals/suggestions", { method: "GET" });
            if (!suggestions.length) {
                suggestionsList.innerHTML = `
                    <div class="col-12">
                        <div class="alert alert-success mb-0">No hay sugerencias disponibles ahora.</div>
                    </div>
                `;
                return;
            }
            suggestionsList.innerHTML = suggestions
                .map(
                    (suggestion) => `
                        <div class="col-md-4">
                            <div class="card border-0 shadow-sm h-100">
                                <div class="card-body">
                                    <div class="icon-circle bg-sb-accent-subtle text-sb-dark mb-3">
                                        <span class="fs-4">💡</span>
                                    </div>
                                    <p class="text-sb-dark fw-semibold mb-2">${suggestion}</p>
                                    <button class="btn btn-outline-success btn-sm" data-suggestion="${suggestion}">
                                        Crear esta meta
                                    </button>
                                </div>
                            </div>
                        </div>
                    `
                )
                .join("");
            suggestionsList.querySelectorAll("button[data-suggestion]").forEach((button) => {
                button.addEventListener("click", () => preloadSuggestion(button.dataset.suggestion));
            });
        } catch (error) {
            console.error(error);
            suggestionsList.innerHTML = `
                <div class="col-12">
                    <div class="alert alert-warning mb-0">No fue posible cargar sugerencias.</div>
                </div>
            `;
        }
    }

    async function loadGoals() {
        try {
            const goals = await request("/goals/");
            if (!goals.length) {
                goalsTable.innerHTML = `
                    <tr>
                        <td colspan="5" class="text-center text-secondary py-4">No hay metas registradas.</td>
                    </tr>
                `;
                return;
            }
            goalsTable.innerHTML = goals
                .map(
                    (goal) => `
                        <tr>
                            <td>
                                <div class="fw-semibold text-sb-dark">${goal.name}</div>
                                <div class="text-secondary small">${goal.description ?? ""}</div>
                            </td>
                            <td>
                                <div class="progress" style="height: 8px;">
                                    <div class="progress-bar bg-sb-accent" role="progressbar" style="width: ${calculateProgress(
                                        goal
                                    )}%;"></div>
                                </div>
                                <div class="text-secondary small mt-1">
                                    ${utils.formatCurrency(goal.current_amount)} / ${utils.formatCurrency(goal.target_amount)}
                                </div>
                            </td>
                            <td><span class="badge ${statusBadge(goal.status)} text-uppercase">${goal.status}</span></td>
                            <td>${goal.target_date ? utils.formatDate(goal.target_date) : "-"}</td>
                            <td class="text-end">
                                <button class="btn btn-sm btn-outline-success" data-update="${goal.id}">Actualizar progreso</button>
                            </td>
                        </tr>
                    `
                )
                .join("");

            goalsTable.querySelectorAll("button[data-update]").forEach((button) => {
                button.addEventListener("click", () => handleProgressUpdate(button.dataset.update, goals));
            });
        } catch (error) {
            console.error(error);
            goalsTable.innerHTML = `
                <tr>
                    <td colspan="5" class="text-center text-secondary py-4">No fue posible cargar las metas.</td>
                </tr>
            `;
        }
    }

    function calculateProgress(goal) {
        if (!goal.target_amount) return 0;
        return Math.min(100, Math.round((goal.current_amount / goal.target_amount) * 100));
    }

    function statusBadge(status) {
        switch (status) {
            case "achieved":
                return "text-bg-success";
            case "missed":
                return "text-bg-danger";
            case "in_progress":
                return "text-bg-warning";
            default:
                return "text-bg-light text-secondary";
        }
    }

    function preloadSuggestion(text) {
        goalForm.goalName.value = text;
        goalForm.goalDescription.value = text;
        goalForm.goalAmount.value = "";
        goalForm.goalDate.value = "";
        goalModal?.show();
    }

    async function handleProgressUpdate(goalId, goals) {
        const goal = goals.find((item) => item.id === goalId);
        if (!goal) return;
        const value = prompt(
            `Monto actual para "${goal.name}" (objetivo ${utils.formatCurrency(goal.target_amount)}):`,
            goal.current_amount
        );
        if (value === null) return;
        const amount = Number(value);
        if (Number.isNaN(amount)) {
            showAlert(alertContainer, "Ingresa un monto válido.", "warning");
            return;
        }
        try {
            await request(`/goals/${goalId}/progress?amount=${amount}`, { method: "POST" });
            showAlert(alertContainer, "Progreso actualizado correctamente.", "success");
            await loadGoals();
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible actualizar el progreso.", "danger");
        }
    }
});
