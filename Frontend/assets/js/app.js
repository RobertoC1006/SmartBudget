document.addEventListener("DOMContentLoaded", () => {
    const yearLabel = document.getElementById("currentYear");
    if (yearLabel) {
        yearLabel.textContent = String(new Date().getFullYear());
    }
    if (window.SB) {
        window.SB.renderNavigation("[data-nav-list]");
        window.SB.renderUserBadge("[data-user-badge]");
    }
});
