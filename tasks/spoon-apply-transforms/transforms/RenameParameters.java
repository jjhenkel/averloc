package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class RenameParameters extends Renamer<CtParameter> {
    // Parameters to this renaming transform
    final static int NAME_MIN_LENGTH = 1;
    final static int NAME_MAX_LENGTH = 5;
    final static double RENAME_PERCENT = 1.0;
    final static Boolean SHUFFLE_MODE = false;

	@Override
	public void transform(CtExecutable method) {
        // Get setup for renaming
        setDefs(getChildrenOfType(method, CtParameter.class));
        setSubtokens(AverlocTransformer.TOP_N_TARGET_SUBTOKENS);
        
        // Select some percentage of things to rename
        takePercentage(RENAME_PERCENT);

        // Build new names and apply them
        applyRenaming(method, false, generateRenaming(
            SHUFFLE_MODE, NAME_MIN_LENGTH, NAME_MAX_LENGTH
        ));
	}
}
