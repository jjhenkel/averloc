package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class Identity extends AverlocTransformer {
	@Override
	public void transform(CtExecutable method) {
		this.setChanged(method);
	}
}
