import json

pets = [
    {
        "id": "su8f8a2c-5f3a-7b12-8c4e-9f3a6b7c2d10",
        "name": "Sushi",
        "species": "dog",
        "photos": [
            "sushi-1.png",
            "sushi-2.png",
            "sushi-3.png"
        ],
    },
    {
        "id": "tu8f8a2c-5f3a-7b12-8c4e-9f3a6b7c2d11",
        "name": "Tuna",
        "species": "cat",
        "photos": [
            "tuna-1.png",
            "tuna-2.png",
            "tuna-3.png"
        ],
    },
    {
        "id": "ta8f8a2c-5f3a-7b12-8c4e-9f3a6b7c2d14",
        "name": "Taco",
        "species": "ferret",
        "photos": [
            "taco-1.png",
            "taco-2.png",
            "taco-3.png"
        ],
    }
]



def lambda_handler(event, context):
    print("Event received")
    print(json.dumps(event, indent=2))
    body = json.dumps(pets, indent=2)
    response = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": body,
    }
    return response
