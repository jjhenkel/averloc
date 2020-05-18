package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class RenameLocalVariables extends Renamer<CtLocalVariable> {
    public RenameLocalVariables(int uid) {
        this.setUID(uid);
    }

	@Override
	public void transform(CtExecutable method) {
        // Reset prior to next transform
        reset();

        // Get setup for renaming
        setDefs(getChildrenOfType(method, CtLocalVariable.class));
        
        takeSingle();

        // Build new names and apply them
        applyTargetedRenaming(method, false);
	}
}
