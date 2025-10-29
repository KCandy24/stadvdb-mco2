PLAYS = [
    "A Midsummer Night's Dream",
    "Death of a Salesman",
    "Hamlet",
    "Waiting for Godot",
]

THEATERS = [
    "Apollo Theater",
    "Newport Performing Arts Theater",
    "Phoenix Wonderland Wonder Stage",
    "Tanghalang Pambansa",
]

SHOWINGS = [
    {"play": "A Midsummer Night's Dream", "theater": "Apollo Theater"},
    {"play": "A Midsummer Night's Dream", "theater": "Phoenix Wonderland Wonder Stage"},
    {"play": "Death of a Salesman", "theater": "Phoenix Wonderland Wonder Stage"},
    {"play": "Hamlet", "theater": "Newport Performing Arts Theater"},
]

SEAT_LAYOUTS = [
    {
        "theater": "Apollo Theater",
        "rows": 3,
        "cols": 10,
        "layout": "0001111000\n0011111100\n0111111110",
    },
    {
        "theater": "Phoenix Wonderland Wonder Stage",
        "rows": 3,
        "cols": 10,
        "layout": "1111111111\n1111111111\n1111111111\n",
    },
    {
        "theater": "Newport Performing Arts Theater",
        "rows": 4,
        "cols": 10,
        "layout": "0101010101\n1010101010\n1010101010\n0101010101",
    },
    {
        "theater": "Tanghalang Pambansa",
        "rows": 1,
        "cols": 1,
        "layout": "0",
    },
]
