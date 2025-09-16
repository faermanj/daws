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
    
def handle_create(event, conn):
    params = event['queryStringParameters'] or {}
    pet = Pet(
        name=params.get('name', ''),
        date_of_birth=params.get('date_of_birth', None),
        species=params.get('species', ''),
    )
    pet_id = Pet.create(pet, conn)
    return {'pet_id': pet_id}

def handle_read(event, conn):
    pet_id = int(event['queryStringParameters'].get('pet_id', 0))
    pet = Pet.get(pet_id, conn)
    return pet.__dict__ if pet else None

def handle_update(event, conn):
    params = event['queryStringParameters'] or {}
    pet = Pet(
        pet_id=int(params.get('pet_id', 0)),
        name=params.get('name', ''),
        date_of_birth=params.get('date_of_birth', None),
        species=params.get('species', ''),
    )
    Pet.update(pet, conn)
    return {'pet_id': pet.pet_id}

def handle_delete(event, conn):
    pet_id = int(event['queryStringParameters'].get('pet_id', 0))
    Pet.delete(pet_id, conn)
    return {'pet_id': pet_id}

def handle_list(conn):
    pets = Pet.list_all(conn)
    return [pet.__dict__ for pet in pets]


with get_db_connection() as conn:
    Pet.create_table(conn)

def lambda_handler(event, context):
    print(json.dumps(event))
    params = event.get('queryStringParameters') or {}
    has_action = 'action' in params
    with get_db_connection() as conn:
        if has_action:
            action = event['queryStringParameters'].get('action')
            result = None
            if action == 'create':
                result = handle_create(event, conn)
            elif action == 'read':
                result = handle_read(event, conn)
            elif action == 'update':
                result = handle_update(event, conn)
            elif action == 'delete':
                result = handle_delete(event, conn)
        else:
            result = handle_list(conn)
        response = {
            "statusCode": 200,
            "body": json.dumps(result, default=str)
        }
        return response
