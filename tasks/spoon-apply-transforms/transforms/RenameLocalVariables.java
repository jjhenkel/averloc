package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class RenameLocalVariables extends Renamer<CtLocalVariable> {
    protected int NAME_MIN_LENGTH = 1;
    protected int NAME_MAX_LENGTH = 5;
    protected double RENAME_PERCENT = 0.80;
    protected Boolean SHUFFLE_MODE = false;

    public RenameLocalVariables(int nameMinLength, int nameMaxLength, double renamePercent, ArrayList<String> topTargetSubtokens) {
        this.NAME_MIN_LENGTH = nameMinLength;
        this.NAME_MAX_LENGTH = nameMaxLength;
        this.RENAME_PERCENT = renamePercent;
        this.setTopTargetSubtokens((ArrayList<String>)topTargetSubtokens.clone());
    }

	@Override
	public void transform(CtExecutable method) {
        // Reset prior to next transform
        reset();

        // Get setup for renaming
        setDefs(getChildrenOfType(method, CtLocalVariable.class));
        setSubtokens(topTargetSubtokens);
        setPrefix("RLV");
        
        // Select some percentage of things to rename
        takePercentage(RENAME_PERCENT);

        // Build new names and apply them
        applyRenaming(method, false, generateRenaming(
            method, SHUFFLE_MODE, NAME_MIN_LENGTH, NAME_MAX_LENGTH
        ));
	}
}
