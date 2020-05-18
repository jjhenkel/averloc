package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class ReplaceTrueFalse extends AverlocTransformer {
  protected int UID = 0;

  public ReplaceTrueFalse(int uid) {
    this.UID = uid;
  }

	@Override
	public void transform(CtExecutable method) {
    ArrayList<CtLiteral> literals = getChildrenOfType(
      method, CtLiteral.class
    );
    
    literals.removeIf(
      x -> x.getValue() == null || !(x.getValue() instanceof Boolean)
    );

    if (literals.size() <= 0) {
      return;
    }

    Collections.shuffle(literals);
    CtLiteral target = literals.get(0);

    CtBinaryOperator<Boolean> replacement = getFactory().Code().createBinaryOperator(
      getFactory().Code().createLiteral("REPLACEME" + Integer.toString(this.UID)), 
      getFactory().Code().createLiteral("REPLACEME" + Integer.toString(this.UID)), 
      ((Boolean)target.getValue()) ? BinaryOperatorKind.EQ : BinaryOperatorKind.NE
    );

    target.replace(replacement);
    this.setChanged(method);
	}
}
