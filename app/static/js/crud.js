/**
 * These are events that are triggered in the admin dashboard table views
 */
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('button.update').forEach(updateButton => {
        updateButton.addEventListener('click', () => {
            const row = updateButton.dataset.row;
            const dataCells = document.querySelectorAll(`tr#row-${row} > td.data-cell`);
            dataCells.forEach(cell => {
                const name = `column.${cell.dataset.column}`;
                const nameOld = `column.old.${cell.dataset.column}`;
                const value = cell.dataset.value;
                const field = document.querySelector(`div#update-modal form#update-form input[name="${name}"]`)
                const fieldOld = document.querySelector(`div#update-modal form#update-form input[name="${nameOld}"]`)
                if (field) field.value = value;
                if (fieldOld) fieldOld.value = value;
            })
        })
    });

    document.querySelectorAll('button.delete').forEach(deleteButton => {
        deleteButton.addEventListener('click', () => {
            const row = deleteButton.dataset.row;
            const dataCells = document.querySelectorAll(`tr#row-${row} > td.data-cell`);
            dataCells.forEach(cell => {
                const name = `column.${cell.dataset.column}`;
                const value = cell.dataset.value;
                const input = document.querySelector(`div#delete-modal > form#delete-form > input[name="${name}"]`);
                if (input) input.value = value;
            })
        })
    });
})