document.addEventListener("DOMContentLoaded", async () => {
    if (!window.SB) return;
    const { initProtectedPage, request, utils, showAlert, config } = window.SB;

    const alertContainer = document.getElementById("alertContainer");
    const manualForm = document.getElementById("manualExpenseForm");
    const ocrForm = document.getElementById("ocrExpenseForm");
    const expensesTable = document.getElementById("expensesList");
    const filterCategory = document.getElementById("filterCategory");

    const receiptFileInput = document.getElementById("receiptFile");
    const processReceiptBtn = document.getElementById("processReceiptBtn");
    const saveOcrExpenseBtn = document.getElementById("saveOcrExpenseBtn");
    const ocrDescription = document.getElementById("ocrDescription");
    const ocrAmount = document.getElementById("ocrAmount");
    const ocrCategory = document.getElementById("ocrCategory");
    const ocrExpenseDate = document.getElementById("ocrExpenseDate");
    const ocrRawText = document.getElementById("ocrRawText");
    const ocrStatus = document.getElementById("ocrStatus");

    const ocrWebhookUrl = config?.OCR_WEBHOOK_URL || config?.ocrWebhookUrl || null;
    const allowedCategories = new Set([
        "alimentacion",
        "transporte",
        "servicios",
        "ocio",
        "salud",
        "educacion",
        "ropa",
        "vivienda",
        "otros",
        "general",
    ]);

    let lastAutomationPayload = null;
    let lastAutomationProvider = "n8n-webhook";
    let lastOcrConfidence = null;

    try {
        await initProtectedPage();
        await loadExpenses();
    } catch (error) {
        showAlert(alertContainer, error.message || "No se pudo cargar la informaciÃ³n.", "danger");
    }

    if (!ocrWebhookUrl) {
        setOcrStatus(
            "Configura la URL del webhook de N8N para habilitar el escaneo de boletas.",
            "danger"
        );
    } else {
        setOcrStatus(
            "Sube una boleta para enviarla a tu automatización N8N. Los campos se completarán automáticamente.",
            "secondary"
        );
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
            showAlert(alertContainer, "Completa descripciÃ³n, monto y categorÃ­a.", "warning");
            return;
        }

        const submitButton = manualForm.querySelector("button");
        submitButton.disabled = true;

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
            submitButton.disabled = false;
        }
    });

    processReceiptBtn.addEventListener("click", async () => {
        if (!receiptFileInput.files?.length) {
            showAlert(alertContainer, "Selecciona un archivo para procesar.", "warning");
            receiptFileInput.focus();
            return;
        }
        if (!ocrWebhookUrl) {
            showAlert(
                alertContainer,
                "Configura la URL del webhook de N8N para poder procesar boletas desde esta sección.",
                "warning"
            );
            return;
        }

        clearOcrInputs();
        saveOcrExpenseBtn.disabled = true;
        processReceiptBtn.disabled = true;
        setOcrStatus("Procesando archivo, esto puede tomar unos segundosâ€¦", "info");

        try {
            const file = receiptFileInput.files[0];
            const result = await runAutomationWebhook(file);

            fillOcrFields(result);
            syncManualForm(result);

            lastAutomationPayload = result.rawPayload || result.structuredData || result;
            lastAutomationProvider = result.provider || lastAutomationProvider;
            lastOcrConfidence = result.ocrConfidence ?? null;

            const hasStructuredData =
                result.hasStructuredData ?? Boolean(result.description || result.amount || result.rawText);

            if (!hasStructuredData) {
                setOcrStatus(
                    "La automatización no detectó descripción ni monto. Completa los campos manualmente antes de registrar.",
                    "warning"
                );
                showAlert(
                    alertContainer,
                    "No se detectaron datos en la boleta. Puedes escribirlos manualmente y luego registrar el gasto.",
                    "warning"
                );
            } else {
                setOcrStatus("Revisa y ajusta los campos antes de registrar el gasto.", "success");
                showAlert(
                    alertContainer,
                    "Datos detectados desde la automatización. Verifica antes de registrar.",
                    "info"
                );
            }
        } catch (error) {
            console.error(error);
            setOcrStatus(error.message || "No fue posible procesar el archivo.", "danger");
            showAlert(alertContainer, error.message || "No fue posible procesar el archivo.", "danger");
        } finally {
            processReceiptBtn.disabled = false;
        }
    });

    ocrForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        if (!ocrWebhookUrl) {
            showAlert(
                alertContainer,
                "Configura la URL del webhook de N8N para registrar gastos desde esta secciÃ³n.",
                "warning"
            );
            return;
        }

        const payload = buildOcrExpensePayload();
        if (!payload.description || !payload.amount || !payload.category) {
            showAlert(alertContainer, "Completa descripciÃ³n, monto y categorÃ­a antes de registrar.", "warning");
            return;
        }

        saveOcrExpenseBtn.disabled = true;
        setOcrStatus("Guardando gasto con los datos reconocidosâ€¦", "info");

        try {
            await request("/expenses/", { method: "POST", body: payload });
            const budget = await request("/budgets/current");
            const remainingText = budget
                ? ` Saldo disponible: ${utils.formatCurrency(budget.remaining, budget.currency || "PEN")}.`
                : "";
            showAlert(alertContainer, `Gasto OCR registrado correctamente.${remainingText}`, "success");
            resetOcrFormState();
            await loadExpenses();
        } catch (error) {
            console.error(error);
            saveOcrExpenseBtn.disabled = false;
            setOcrStatus(error.message || "No fue posible guardar el gasto.", "danger");
            showAlert(alertContainer, error.message || "No fue posible guardar el gasto.", "danger");
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

    async function runAutomationWebhook(file) {
        if (!ocrWebhookUrl) {
            throw new Error("No se encontrÃ³ la URL del webhook de automatizaciÃ³n.");
        }

        const formData = new FormData();
        formData.append("file", file, file.name);

        const response = await fetch(ocrWebhookUrl, {
            method: "POST",
            body: formData,
        });

        const raw = await response.text();
        let data;
        try {
            data = raw ? JSON.parse(raw) : {};
        } catch (error) {
            data = raw ? { raw } : {};
        }

        if (!response.ok) {
            const message =
                typeof data === "string"
                    ? data
                    : data?.detail || data?.message || data?.error || "La automatizaciÃ³n devolviÃ³ un error.";
            throw new Error(message);
        }

        const normalized = normalizeAutomationPayload(data);
        normalized.hasStructuredData = Boolean(normalized.description || normalized.amount);
        return normalized;
    }

    function normalizeAutomationPayload(payload) {
        const source = Array.isArray(payload) ? payload[0] : payload;
        const candidate =
            typeof source?.data === "object" && !Array.isArray(source.data) ? source.data : source?.body ?? source;

        const valueFrom = (...keys) => {
            for (const key of keys) {
                const value = readNested(candidate, key) ?? readNested(source, key);
                if (value !== undefined && value !== null && value !== "") {
                    return value;
                }
            }
            return undefined;
        };

        const description = valueFrom("description", "descripcion", "data.description");
        const amount = toNumber(valueFrom("amount", "monto", "total"));
        const category = normalizeCategory(valueFrom("category", "categoria"));
        const expenseDate = normalizeDate(valueFrom("expense_date", "fecha", "date"));
        const rawText = valueFrom(
            "raw_text",
            "texto",
            "texto_normalizado",
            "ocr_text",
            "full_text",
            "ocr.raw",
            "result"
        );
        const currency = valueFrom("currency", "moneda");

        return {
            description: description || "",
            amount: amount || "",
            category: category || "general",
            expenseDate,
            rawText: typeof rawText === "string" ? rawText : JSON.stringify(rawText ?? {}, null, 2),
            currency,
            provider: "n8n-webhook",
            rawPayload: payload,
        };
    }

    function readNested(obj, path) {
        if (!obj || typeof obj !== "object" || !path) return undefined;
        const segments = path.split(".");
        let current = obj;
        for (const segment of segments) {
            if (current && Object.prototype.hasOwnProperty.call(current, segment)) {
                current = current[segment];
            } else {
                return undefined;
            }
        }
        return current;
    }

    function normalizeCategory(value) {
        if (!value) return "";
        const normalized = value
            .toString()
            .trim()
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "");
        if (allowedCategories.has(normalized)) {
            return normalized;
        }
        const aliases = {
            comida: "alimentacion",
            supermercado: "alimentacion",
            market: "alimentacion",
            transporte_publico: "transporte",
            gasolina: "transporte",
            luz: "servicios",
            agua: "servicios",
            entretenimiento: "ocio",
            medicina: "salud",
            doctor: "salud",
            colegio: "educacion",
            universidad: "educacion",
        };
        return aliases[normalized] || "";
    }

    function toNumber(value) {
        if (value === undefined || value === null || value === "") return undefined;
        if (typeof value === "number" && !Number.isNaN(value)) return value;
        const cleaned = value.toString().replace(/[^\d,.-]/g, "").replace(",", ".");
        const parsed = Number(cleaned);
        return Number.isNaN(parsed) ? undefined : parsed;
    }

    function normalizeDate(value) {
        if (!value) return undefined;
        if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value;
        const parsed = new Date(value);
        if (Number.isNaN(parsed.getTime())) return undefined;
        return parsed.toISOString().slice(0, 10);
    }

    function fillOcrFields(data) {
        if (data.description) {
            ocrDescription.value = data.description;
        }
        if (data.amount !== undefined && data.amount !== null && data.amount !== "") {
            ocrAmount.value = data.amount;
        }
        if (data.category) {
            ocrCategory.value = data.category;
        }
        if (data.expenseDate) {
            ocrExpenseDate.value = data.expenseDate;
        }
        if (typeof data.rawText === "string") {
            ocrRawText.value = data.rawText;
        }
    }

    function syncManualForm(data) {
        if (data.description) {
            manualForm.description.value = data.description;
        }
        if (data.amount) {
            manualForm.amount.value = data.amount;
        }
        if (data.category && allowedCategories.has(data.category)) {
            manualForm.category.value = data.category;
        }
        if (data.expenseDate) {
            manualForm.expense_date.value = data.expenseDate;
        }
    }

    function buildOcrExpensePayload() {
        const extra = {
            ocr_provider: lastAutomationProvider,
            ocr_confidence: lastOcrConfidence,
            ocr_raw_text: ocrRawText.value.trim() || undefined,
            ocr_payload: lastAutomationPayload,
        };
        Object.keys(extra).forEach((key) => {
            if (extra[key] === undefined || extra[key] === null || extra[key] === "") {
                delete extra[key];
            }
        });

        return {
            description: ocrDescription.value.trim(),
            amount: Number(ocrAmount.value),
            category: ocrCategory.value || "general",
            expense_date: ocrExpenseDate.value || undefined,
            source: "ocr",
            extra_data: Object.keys(extra).length ? extra : undefined,
        };
    }

    function resetOcrFormState() {
        clearOcrInputs();
        receiptFileInput.value = "";
        saveOcrExpenseBtn.disabled = true;
        setOcrStatus(
            "Sube otra boleta para volver a completar los campos automÃ¡ticamente.",
            "secondary"
        );
        lastAutomationPayload = null;
        lastOcrConfidence = null;
    }

    function setOcrStatus(message, tone) {
        if (!ocrStatus) return;
        const color = tone || "secondary";
        ocrStatus.className = `small text-${color}`;
        ocrStatus.textContent = message;
    }

    function clearOcrInputs() {
        ocrDescription.value = "";
        ocrAmount.value = "";
        ocrCategory.value = "";
        ocrExpenseDate.value = "";
        ocrRawText.value = "";
    }
});
