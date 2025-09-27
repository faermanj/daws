package daws.fn;

import java.util.Set;

import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;
import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;

import java.util.Set;

import daws.api.PetResource;


@ApplicationPath("/")
public class CrudApiApplication extends Application {

    @Override
    public Set<Class<?>> getClasses() {
        return Set.of(
            PetResource.class
        );
    }
}

