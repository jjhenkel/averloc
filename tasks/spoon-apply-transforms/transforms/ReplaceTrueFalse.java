package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class ReplaceTrueFalse extends AverlocTransformer {
  // Parameters to this renaming transform
  protected double REPLACMENT_CHANCE = 1.0;

  public ReplaceTrueFalse(double replacementChance) {
    this.REPLACMENT_CHANCE = replacementChance;
  }

	@Override
	public void transform(CtExecutable method) {
    Random rand = new Random();

    if (rand.nextDouble() >= REPLACMENT_CHANCE) {
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
