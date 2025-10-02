package petoboto.api;

import java.util.ArrayList;
import java.util.List;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.OrderColumn;

@Entity
public class Pet extends PanacheEntity {
    private String name;
    private PetKind kind;
    
    //TODO: Map pictures to a separate table
    private List<String> pictures = new ArrayList<>();
    
    public static Pet create(String name, PetKind kind, List<String> pictures) {

        var pet = new Pet();
        pet.name = name;
        pet.kind = kind;
        pet.pictures = pictures;
        pet.persist();
        return pet;
    }

    public Pet() {
    }

    public String toString() {
        return "Pet{id=" + id + ", name=" + name + ", kind=" + kind + "}";
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public PetKind getKind() {
        return kind;
    }

    public void setKind(PetKind kind) {
        this.kind = kind;
    }

    public List<String> getPictures() {
        return pictures;
    }

    public void setPictures(List<String> pictures) {
        this.pictures = pictures;
    }

}
