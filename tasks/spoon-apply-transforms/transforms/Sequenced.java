package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

public class Sequenced extends AverlocTransformer {
  ArrayList<AverlocTransformer> subTransformers;

  public Sequenced(ArrayList<AverlocTransformer> subTransformers, String name) {
    this.subTransformers = subTransformers;
    this.name = name;
  }

	@Override
	public void transform(CtExecutable method) {
    for (AverlocTransformer transformer : subTransformers) {
      transformer.setFactory(getFactory());
      transformer.transform(method);
      if (transformer.changes(((CtTypeMember)method).getDeclaringType().getSimpleName())) {
        this.setChanged(method);
      }
    }
	}
}
