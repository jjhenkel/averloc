package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class WrapTryCatch extends AverlocTransformer {
  // Parameters to this renaming transform
  protected double REPLACMENT_CHANCE = 1.0;

  public WrapTryCatch(double replacementChance) {
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

    CtTry wrapper = getFactory().Core().createTry();

    wrapper.addCatcher(
      getFactory().Code().createCtCatch(
        "REPLACE_ME_WTC_1",
        java.lang.Exception.class,
        getFactory().Code().createCtBlock(
          getFactory().Code().createCtThrow("REPLACE_ME_WTC_1")
        )
      )
    );

    wrapper.setBody(method.getBody());

    method.setBody(
      getFactory().Code().createCtBlock(
        wrapper
      )
    );

    this.setChanged(method);
	}
}
