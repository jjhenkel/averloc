package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class ReplaceTrueFalse extends AverlocTransformer {
  // Parameters to this renaming transform
  final static int MIN_INSERTIONS = 1;
  final static int MAX_INSERTIONS = 3;
  final static int LITERAL_MIN_LENGTH = 1;
  final static int LITERAL_MAX_LENGTH = 5;
  final static double REPLACMENT_CHANGE = 0.70;

	@Override
	public void transform(CtExecutable method) {
    Random rand = new Random();

    if (rand.nextDouble() >= REPLACMENT_CHANGE) {
      return;
    }

    ArrayList<CtLiteral> literals = getChildrenOfType(
      method, CtLiteral.class
    );

    for (CtLiteral literal : literals) {
      if (literal.getValue() != null && literal.getValue() instanceof Boolean) {
        int randomLiteral = rand.nextBoolean() ? 0 : 1;

        CtBinaryOperator<Boolean> replacement = getFactory().Code().createBinaryOperator(
          getFactory().Code().createLiteral(randomLiteral), 
          getFactory().Code().createLiteral(randomLiteral), 
          ((Boolean)literal.getValue()) ? BinaryOperatorKind.EQ : BinaryOperatorKind.NE
        );

        literal.replace(replacement);
        this.setChanged(method);
      }
    }
	}
}
