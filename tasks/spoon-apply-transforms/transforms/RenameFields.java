package transforms;

import spoon.reflect.factory.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.util.stream.*;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.io.IOException;
import java.lang.Math;

public class RenameFields extends Renamer<CtField> {
  // Parameters to this renaming transform
  final static int NAME_MIN_LENGTH = 1;
  final static int NAME_MAX_LENGTH = 5;
  final static double RENAME_PERCENT = 0.50;
  final static Boolean SHUFFLE_MODE = false;

	@Override
	public void transform(CtExecutable method) {
    // Find field references with no declaring type. These should
    // be fields of the enclosing class but, since we just have a method
    // we've lost the enclosing class
    ArrayList<CtFieldReference> fieldReferences = new ArrayList<CtFieldReference>(
      getChildrenOfType(
        method, CtFieldReference.class
      ).stream().filter(
        // Only want ones from our class
        fieldRef -> fieldRef.getDeclaringType() == null
      ).collect(
        Collectors.toList()
      )
    );

    // First, collect unique field names
    ArrayList<String> fieldNames = new ArrayList<String>();
    for (CtFieldReference fieldRef : fieldReferences) {
      if (!fieldNames.contains(fieldRef.getSimpleName())) {
        fieldNames.add(fieldRef.getSimpleName());
      }
    }

    // Next, we'll go ahead and make a fake class to hold
    // generated field declerations
    final CtClass<Object> fakedClass = getFactory().Class().create("Faked");

    // Then, we'll build the field declarations (virtually)
    // and attach them to our fake class (and save them for our
    // renamer to use later)
    ArrayList<CtField> fieldDecls = new ArrayList<CtField>();
    for (String fieldName : fieldNames) {
      CtField<String> generatedField = fakedClass.getFactory().Field().create(
        null,
        new HashSet<>(),
        fakedClass.getFactory().Type().STRING,
        fieldName
      );

      fakedClass.addField(generatedField);
      fieldDecls.add(generatedField);
    }

    // Finally, we'll go ahead and link our references to the faked
    // declarations (thus, placing us in a state where we can use our
    // renamer logic)
    for (CtFieldReference fieldRef : fieldReferences) {
      for (CtField<String> fieldDecl : fieldDecls) {
        if (fieldDecl.getSimpleName().equals(fieldRef.getSimpleName())) {
          fieldRef.setDeclaringType(
            fakedClass.getFactory().Type().createReference(
              fieldDecl.getDeclaringType()
            )
          );
        }
      }
    }

    // Get setup for renaming (use the fieldDecls we crafted earlier)
    setDefs(fieldDecls);
    setSubtokens(AverlocTransformer.TOP_N_TARGET_SUBTOKENS);
    
    // Select some percentage of things to rename
    takePercentage(RENAME_PERCENT);

    // Build new names and apply them (true ==> to skip decls)
    applyRenaming(method, true, generateRenaming(
        SHUFFLE_MODE, NAME_MIN_LENGTH, NAME_MAX_LENGTH
    ));
	}
}
