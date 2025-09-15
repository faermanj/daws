import json
import os
import pymysql
from contextlib import contextmanager
from pet import Pet


@contextmanager
def get_db_connection():
    conn = pymysql.connect(
        host=os.environ.get('MYSQL_HOST', 'localhost'),
        user=os.environ.get('MYSQL_USER', 'root'),
        password=os.environ.get('MYSQL_PASSWORD', ''),
        database=os.environ.get('MYSQL_DATABASE', ''),
        port=int(os.environ.get('MYSQL_PORT', 3306)),
        cursorclass=pymysql.cursors.DictCursor
    )
    try:
        yield conn
    finally:
        conn.close()

with get_db_connection() as conn:
    Pet.create_table(conn)


def lambda_handler(event, context):
    print(json.dumps(event))
    status = "unknown"
    action = None
    if 'queryStringParameters' in event and event['queryStringParameters']:
        action = event['queryStringParameters'].get('action')
    result = None
    with get_db_connection() as conn:
        if action == 'create':
            # Example: expects name, date_of_birth, species in query params
            params = event['queryStringParameters'] or {}
            pet = Pet(
                name=params.get('name', ''),
                date_of_birth=params.get('date_of_birth', None),
                species=params.get('species', ''),
            )
            pet_id = Pet.create(pet, conn)
            result = {'pet_id': pet_id}
            status = 'created'
        elif action == 'read':
            pet_id = int(event['queryStringParameters'].get('pet_id', 0))
            pet = Pet.get(pet_id, conn)
            result = pet.__dict__ if pet else None
            status = 'read'
        elif action == 'update':
            params = event['queryStringParameters'] or {}
            pet = Pet(
                pet_id=int(params.get('pet_id', 0)),
                name=params.get('name', ''),
                date_of_birth=params.get('date_of_birth', None),
                species=params.get('species', ''),
            )
            Pet.update(pet, conn)
            result = {'pet_id': pet.pet_id}
            status = 'updated'
        elif action == 'delete':
            pet_id = int(event['queryStringParameters'].get('pet_id', 0))
            Pet.delete(pet_id, conn)
            result = {'pet_id': pet_id}
            status = 'deleted'
        else:
            pets = Pet.list_all(conn)
            result = [pet.__dict__ for pet in pets]
            status = 'listed'
    response = {
        "statusCode": 200,
        "body": json.dumps({
            "action": action,
            "status": status,
            "result": result
        }, default=str)
    }
    return response
