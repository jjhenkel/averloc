package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class RenameParameters extends Renamer<CtParameter> {
    public RenameParameters(int uid) {
        this.setUID(uid);
    }

	@Override
	public void transform(CtExecutable method) {
        // Reset prior to next transform
        reset();
        
        // Get setup for renaming
        setDefs(getChildrenOfType(method, CtParameter.class));
        
        takeSingle();

        // Build new names and apply them
        applyTargetedRenaming(method, false);
	}
}
