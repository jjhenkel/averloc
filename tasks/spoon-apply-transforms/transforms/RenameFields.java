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
  protected int NAME_MIN_LENGTH = 1;
  protected int NAME_MAX_LENGTH = 5;
  protected double RENAME_PERCENT = 1.0;
  protected Boolean SHUFFLE_MODE = false;

  public RenameFields(int nameMinLength, int nameMaxLength, double renamePercent, ArrayList<String> topTargetSubtokens) {
      this.NAME_MIN_LENGTH = nameMinLength;
      this.NAME_MAX_LENGTH = nameMaxLength;
      this.RENAME_PERCENT = renamePercent;
      this.setTopTargetSubtokens((ArrayList<String>)topTargetSubtokens.clone());
  }

	@Override
	public void transform(CtExecutable method) {
    // Reset prior to next transform
    reset();

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

    // Then, we'll build the field declarations (virtually)
    // and attach them to our fake class (and save them for our
    // renamer to use later)
    ArrayList<CtField> fieldDecls = new ArrayList<CtField>();
    for (String fieldName : fieldNames) {
      CtField<String> generatedField = ((CtTypeMember)method).getDeclaringType().getFactory().Field().create(
        null,
        new HashSet<>(),
        ((CtTypeMember)method).getDeclaringType().getFactory().Type().STRING,
        fieldName
      );

      ((CtTypeMember)method).getDeclaringType().addField(generatedField);
      fieldDecls.add(generatedField);
    }

    // Finally, we'll go ahead and link our references to the faked
    // declarations (thus, placing us in a state where we can use our
    // renamer logic)
    for (CtFieldReference fieldRef : fieldReferences) {
      for (CtField<String> fieldDecl : fieldDecls) {
        if (fieldDecl.getSimpleName().equals(fieldRef.getSimpleName())) {
          fieldRef.setDeclaringType(
            ((CtTypeMember)method).getDeclaringType().getFactory().Type().createReference(
              fieldDecl.getDeclaringType()
            )
          );
        }
      }
    }

    // Get setup for renaming (use the fieldDecls we crafted earlier)
    setDefs(fieldDecls);
    setSubtokens(topTargetSubtokens);
    setPrefix("RF");
    
    // Select some percentage of things to rename
    takePercentage(RENAME_PERCENT);

    // Build new names and apply them (true ==> to skip decls)
    applyRenaming(method, true, generateRenaming(
        method, SHUFFLE_MODE, NAME_MIN_LENGTH, NAME_MAX_LENGTH
    ));

    // Cleanup: remove fields from WRAPPER class
    for (CtField<String> generatedField : fieldDecls) {
      ((CtTypeMember)method).getDeclaringType().removeField(generatedField);
    }
	}
}
