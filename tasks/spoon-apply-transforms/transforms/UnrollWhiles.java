package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class UnrollWhiles extends AverlocTransformer {
  // Parameters to this renaming transform
  protected int UNROLL_STEPS = 2;

  public UnrollWhiles(int unrollSteps) {
    this.UNROLL_STEPS = unrollSteps;
  }

	@Override
	public void transform(CtExecutable method) {
    ArrayList<CtWhile> whiles = getChildrenOfType(
      method, CtWhile.class
    );

    for (CtWhile theWhile : whiles) {
      if (theWhile.getBody() == null || theWhile.getLoopingExpression() == null) {
        continue;
      }

      CtStatement whileBody = theWhile.getBody();
      CtStatement lastBody = theWhile;

      for (int i = 0; i < this.UNROLL_STEPS; i++) {
        CtIf wrapperIf = getFactory().Core().createIf();

        wrapperIf.setCondition(theWhile.getLoopingExpression().clone());

        CtBlock temp = getFactory().Core().createBlock();
        temp.addStatement(whileBody.clone());
        temp.addStatement(lastBody.clone());

        wrapperIf.setThenStatement(temp);

        lastBody = wrapperIf.clone();
      }

      theWhile.replace(lastBody);
      
      this.setChanged(method);
    }
	}
}
