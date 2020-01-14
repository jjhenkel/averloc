package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class ShuffleParameters extends Renamer<CtParameter> {
    protected int NAME_MIN_LENGTH = 1;
    protected int NAME_MAX_LENGTH = 5;
    protected double RENAME_PERCENT = 1.0;
    protected Boolean SHUFFLE_MODE = true;

    public ShuffleParameters(double shufflePercent) {
        this.RENAME_PERCENT = shufflePercent;
    }

	@Override
	public void transform(CtExecutable method) {
        // Get setup for renaming
        setDefs(getChildrenOfType(method, CtParameter.class));
        setSubtokens(topTargetSubtokens);
        
        // Select some percentage of things to rename
        takePercentage(RENAME_PERCENT);

        // Build new names and apply them
        applyRenaming(method, false, generateRenaming(
            SHUFFLE_MODE, NAME_MIN_LENGTH, NAME_MAX_LENGTH
        ));
	}
}
