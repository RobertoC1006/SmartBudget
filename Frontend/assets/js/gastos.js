document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, request, utils, showAlert } = window.SB;

    const alertContainer = document.getElementById("alertContainer");
    const manualForm = document.getElementById("manualExpenseForm");
    const ocrForm = document.getElementById("ocrExpenseForm");
    const ocrPreview = document.getElementById("ocrPreview");
    const expensesTable = document.getElementById("expensesList");
    const filterCategory = document.getElementById("filterCategory");

    try {
        await initProtectedPage();
        await loadExpenses();
    } catch (error) {
        showAlert(alertContainer, error.message || "No se pudo cargar la información.", "danger");
    }

    manualForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const payload = {
            description: manualForm.description.value.trim(),
            amount: Number(manualForm.amount.value),
            category: manualForm.category.value,
            expense_date: manualForm.expense_date.value || undefined,
        };

        if (!payload.description || !payload.amount || !payload.category) {
            showAlert(alertContainer, "Completa descripción, monto y categoría.", "warning");
            return;
        }

        manualForm.querySelector("button").disabled = true;

        try {
            await request("/expenses/", { method: "POST", body: payload });
            const budget = await request("/budgets/current");
            const remainingText = budget
                ? ` Saldo disponible: ${utils.formatCurrency(budget.remaining, budget.currency || "PEN")}.`
                : "";
            showAlert(alertContainer, `Gasto registrado correctamente.${remainingText}`, "success");
            manualForm.reset();
            await loadExpenses();
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible registrar el gasto.", "danger");
        } finally {
            manualForm.querySelector("button").disabled = false;
        }
    });

    ocrForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const fileInput = document.getElementById("receiptFile");
        if (!fileInput.files?.length) {
            showAlert(alertContainer, "Selecciona un archivo para procesar.", "warning");
            return;
        }

        const formData = new FormData();
        formData.append("file", fileInput.files[0]);

        ocrForm.querySelector("button").disabled = true;
        ocrPreview.value = "Procesando archivo...";

        try {
            const response = await request("/expenses/upload", {
                method: "POST",
                body: formData,
                isFormData: true,
            });
            const { expense, structured_data } = response;
            ocrPreview.value = `
Descripción: ${expense.description}
Categoría: ${expense.category}
Fecha: ${expense.expense_date}
Monto: ${expense.amount}

Texto OCR:
${structured_data?.texto_normalizado ?? "No disponible"}
            `.trim();
            const budget = await request("/budgets/current");
            const remainingText = budget
                ? ` Saldo disponible: ${utils.formatCurrency(budget.remaining, budget.currency || "PEN")}.`
                : "";
            showAlert(
                alertContainer,
                `La boleta fue procesada y registrada automáticamente.${remainingText}`,
                "success"
            );
            fileInput.value = "";
            if (structured_data) {
                if (structured_data.descripcion) {
                    manualForm.description.value = structured_data.descripcion;
                }
                if (structured_data.monto) {
                    manualForm.amount.value = structured_data.monto;
                }
                if (structured_data.fecha) {
                    manualForm.expense_date.value = structured_data.fecha;
                }
                if (structured_data.categoria) {
                    manualForm.category.value = structured_data.categoria.toLowerCase();
                }
            }
            await loadExpenses();
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, error.message || "No fue posible procesar el archivo.", "danger");
            ocrPreview.value = "";
        } finally {
            ocrForm.querySelector("button").disabled = false;
        }
    });

    filterCategory.addEventListener("change", loadExpenses);

    async function loadExpenses() {
        try {
            const category = filterCategory.value;
            const path = category ? `/expenses?category=${category}` : "/expenses";
            const expenses = await request(path);
            if (!expenses.length) {
                expensesTable.innerHTML = `
                    <tr>
                        <td colspan="5" class="text-center text-secondary py-4">No hay gastos para mostrar.</td>
                    </tr>
                `;
                return;
            }
            const currency = expenses[0]?.currency || "PEN";
            expensesTable.innerHTML = expenses
                .map(
                    (expense) => `
                        <tr>
                            <td>${expense.description}</td>
                            <td>${utils.formatDate(expense.expense_date)}</td>
                            <td class="text-capitalize">${expense.category.replace("_", " ")}</td>
                            <td class="text-capitalize">${expense.source}</td>
                            <td class="text-end">${utils.formatCurrency(expense.amount, currency)}</td>
                        </tr>
                    `
                )
                .join("");
        } catch (error) {
            console.error(error);
            showAlert(alertContainer, "No fue posible cargar los gastos.", "danger");
        }
    }
});
