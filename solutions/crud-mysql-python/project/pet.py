from dataclasses import dataclass, field
from datetime import date
from typing import List, Optional

import pymysql


@dataclass
class Pet:

    @classmethod
    def from_row(cls, row, conn=None):
        """Create a Pet instance from a DB row, including picture_files if conn is provided."""
        picture_files = []
        if conn is not None and row:
            with conn.cursor() as cursor:
                cursor.execute("SELECT file_name FROM pictures WHERE pet_id=%s", (row['pet_id'],))
                picture_files = [r['file_name'] for r in cursor.fetchall()]
        return cls(
            pet_id=row['pet_id'],
            name=row['name'],
            date_of_birth=row['date_of_birth'],
            species=row['species'],
            picture_files=picture_files
        )
    pet_id: int = None
    name: str = ""
    date_of_birth: date = None
    species: str = ""
    picture_files: List[str] = field(default_factory=list)

    @staticmethod
    def create_table(conn):
        with conn.cursor() as cursor:
            # Delete pictures table if exists (for demo purposes)
            cursor.execute("DROP TABLE IF EXISTS pictures")
            conn.commit()
            cursor.execute("DROP TABLE IF EXISTS pets")
            conn.commit()
            
            # Create pets table
            sql_pets = (
                """
                CREATE TABLE IF NOT EXISTS pets (
                    pet_id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    date_of_birth DATE,
                    species VARCHAR(255),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            cursor.execute(sql_pets)
            conn.commit()

            # Create pictures table
            sql_pictures = (
                """
                CREATE TABLE IF NOT EXISTS pictures (
                    picture_id INT AUTO_INCREMENT PRIMARY KEY,
                    pet_id INT NOT NULL,
                    file_name VARCHAR(255) NOT NULL,
                    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE
                )
                """
            )
            cursor.execute(sql_pictures)
            conn.commit()

            # Check if pets table is empty
            cursor.execute("SELECT COUNT(*) as count FROM pets")
            count = cursor.fetchone()["count"]
            if count == 0:
                # Insert test data
                test_pets = [
                    ("Sushi", "2020-01-01", "dog", ["sushi-1.png", "sushi-2.png", "sushi-3.png"]),
                    ("Tuna", "2019-05-15", "cat", ["tuna-1.png", "tuna-2.png", "tuna-3.png"]),
                    ("Taco", "2021-07-20", "bird", ["taco-1.png", "taco-2.png", "taco-3.png"])
                ]
                for pet in test_pets:
                    pet_obj = Pet(
                        name=pet[0],
                        date_of_birth=pet[1],
                        species=pet[2],
                        picture_files=pet[3]
                    )
                    pet_id = Pet.create(pet_obj, conn)
                conn.commit()


    @staticmethod
    def create(pet, conn):
        with conn.cursor() as cursor:
            sql = """
                INSERT INTO pets (name, date_of_birth, species)
                VALUES (%s, %s, %s)
            """
            cursor.execute(sql, (pet.name, pet.date_of_birth, pet.species))
            conn.commit()
            pet_id = cursor.lastrowid
            # Insert pictures if provided
            if pet.picture_files:
                picture_rows = [(pet_id, fname) for fname in pet.picture_files]
                cursor.executemany(
                    "INSERT INTO pictures (pet_id, file_name) VALUES (%s, %s)",
                    picture_rows
                )
                conn.commit()
            return pet_id

    @staticmethod
    def get(pet_id, conn) -> Optional['Pet']:
        with conn.cursor() as cursor:
            sql = "SELECT pet_id, name, date_of_birth, species FROM pets WHERE pet_id=%s"
            cursor.execute(sql, (pet_id,))
            row = cursor.fetchone()
            if row:
                return Pet.from_row(row, conn)
            return None

    @staticmethod
    def update(pet, conn):
        with conn.cursor() as cursor:
            sql = """
                UPDATE pets SET name=%s WHERE pet_id=%s
            """
            cursor.execute(sql, (pet.name, pet.pet_id))
            conn.commit()

    @staticmethod
    def delete(pet_id, conn):
        with conn.cursor() as cursor:
            cursor.execute("DELETE FROM pictures WHERE pet_id=%s", (pet_id,))
            sql = "DELETE FROM pets WHERE pet_id=%s"
            cursor.execute(sql, (pet_id,))
            conn.commit()

    @staticmethod
    def list_all(conn) -> List['Pet']:
        with conn.cursor() as cursor:
            sql = "SELECT pet_id, name, date_of_birth, species FROM pets"
            cursor.execute(sql)
            rows = cursor.fetchall()
            return [Pet.from_row(row, conn) for row in rows]
