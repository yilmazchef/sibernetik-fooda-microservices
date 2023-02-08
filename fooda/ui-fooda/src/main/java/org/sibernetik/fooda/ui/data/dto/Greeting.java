package org.sibernetik.fooda.ui.data.dto;


import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.Table;
import java.io.Serializable;
import java.util.Objects;

import lombok.*;
// LOMBOK ANNOTATIONS
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@With
@ToString ( onlyExplicitlyIncluded = true )
@EqualsAndHashCode ( onlyExplicitlyIncluded = true )
// JPA & HIBERNATE ANNOTATIONS
@Entity
@Table ( name = "greetings" )
public class Greeting implements Serializable, Cloneable, Comparable < Greeting > {

    @EqualsAndHashCode.Include
    @Id
    @GeneratedValue (
            strategy = javax.persistence.GenerationType.IDENTITY
    )
    private long id;

    @ToString.Include
    private String content;

    @EqualsAndHashCode.Include
    private String phone;

    @Override
    public int compareTo ( Greeting o ) {
        return Long.compare ( this.id, o.id );
    }

    @Override
    public Greeting clone ( ) {
        try {
            final var clone = ( Greeting ) super.clone ( );
            clone.setId ( - 1L );
            clone.setContent ( this.getContent ( ) );
            clone.setPhone ( this.getPhone ( ) );
            return clone;
        } catch ( CloneNotSupportedException e ) {
            throw new AssertionError ( );
        }
    }
}
