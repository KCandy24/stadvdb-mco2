/**
 * These are events that are triggered in the admin dashboard table views
 */
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('button.update').forEach(updateButton => {
        // TODO: Set
    });

    document.querySelectorAll('button.delete').forEach(deleteButton => {
        // TODO
        const row = deleteButton.dataset.row;
        const dataCells = document.querySelectorAll(`tr#row-${row} > td.data-cell`);
        dataCells.forEach(cell => {
            const name = `column.${cell.dataset.column}`;
            const value = cell.dataset.value;
            document.querySelector(`div#delete-modal > form#delete-form > input[name="${name}"]`).value = value;
        })
    });
})