document.addEventListener('DOMContentLoaded', () => {
    // Seat reservation screen
    let reservedSeats = [];
    const seats = document.querySelectorAll('.seat')
    seats.forEach(seat => {
        seat.addEventListener('click', () => {
            toggleSeat(seat)
        })
    })

    function toggleSeat(seat) {
        const seatId = seat.dataset.seat
        const seatsInput = document.querySelector('input[name=seats]')
        if (reservedSeats.includes(seatId)) {
            const indexToRemove = reservedSeats.indexOf(seatId)
            reservedSeats.splice(indexToRemove, 1)
            seat.classList.remove("seat-chosen")
        } else {
            reservedSeats.push(seatId)
            seat.classList.add("seat-chosen")
        }
        reservedSeats.sort()
        seatsInput.value = reservedSeats.toString()
    }
})