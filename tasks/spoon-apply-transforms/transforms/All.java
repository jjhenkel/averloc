package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class All extends AverlocTransformer {
  ArrayList<AverlocTransformer> subTransformers;

  public All(ArrayList<AverlocTransformer> subTransformers) {
    this.subTransformers = subTransformers;
  }

	@Override
	public void transform(CtExecutable method) {
    for (AverlocTransformer transformer : subTransformers) {
      transformer.transform(method);
      if (transformer.changes(((CtTypeMember)method).getDeclaringType().getSimpleName())) {
        this.setChanged(method);
      }
    }
	}
}
