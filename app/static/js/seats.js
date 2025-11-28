document.addEventListener('DOMContentLoaded', () => {
    // Seat reservation screen
    let reservedSeats = [];
    let totalPrice = 0;
    const baseFee = parseFloat(document.querySelector("input[name=base_fee]").value);
    const seats = document.querySelectorAll('.seat')
    seats.forEach(seat => {
        seat.addEventListener('click', () => {
            toggleSeat(seat)
        })
    })

    function toggleSeat(seat) {
        const seatId = seat.dataset.seatId
        const seatsInput = document.querySelector('input[name=seats]')
        if (reservedSeats.includes(seatId)) {
            const indexToRemove = reservedSeats.indexOf(seatId)
            reservedSeats.splice(indexToRemove, 1)
            seat.classList.remove("seat-chosen")
            totalPrice -= baseFee + parseFloat(seat.dataset.price);
        } else {
            reservedSeats.push(seatId)
            seat.classList.add("seat-chosen")
            totalPrice += baseFee + parseFloat(seat.dataset.price);
        }
        reservedSeats.sort()
        seatsInput.value = reservedSeats.toString()
        document.getElementById("total-price").textContent = `P${totalPrice}`;
    }
})