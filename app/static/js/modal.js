document.addEventListener('DOMContentLoaded', () => {
    const VISIBLE = "modal-visible";

    document.querySelectorAll('button.show-modal').forEach(button => {
        button.addEventListener("click", () => {
            const { modalId } = button.dataset;
            document.querySelectorAll("div.modal").forEach(modal => modal.classList.remove(VISIBLE));
            document.getElementById(modalId).classList.add(VISIBLE);
        })
    })

    document.querySelectorAll('button.close-modal').forEach(button => {
        button.addEventListener("click", () => {
            const { modalId } = button.dataset;
            document.getElementById(modalId).classList.remove(VISIBLE);
        })
    })
})

