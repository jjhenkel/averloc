package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class UnrollWhiles extends AverlocTransformer {
  protected int UNROLL_STEPS = 1;
  protected int UID = 0;

  public UnrollWhiles(int uid) {
    this.UID = uid;
  }

	@Override
	public void transform(CtExecutable method) {
    ArrayList<CtWhile> whiles = getChildrenOfType(
      method, CtWhile.class
    );
    
    whiles.removeIf(
      x -> x.getBody() == null || x.getLoopingExpression() == null
    );

    if (whiles.size() <= 0) {
      return;
    }

    Collections.shuffle(whiles);
    CtWhile target = whiles.get(0);

    CtStatement whileBody = target.getBody();
    CtStatement lastBody = target;

    for (int i = 0; i < this.UNROLL_STEPS; i++) {
      CtWhile wrapperIf = getFactory().Core().createWhile();

      wrapperIf.setLoopingExpression(target.getLoopingExpression().clone());

      CtBlock temp = getFactory().Core().createBlock();
      temp.addStatement(whileBody.clone());
      temp.addStatement(lastBody.clone());
      temp.addStatement(getFactory().Core().createBreak());

      wrapperIf.setBody(temp);

      lastBody = wrapperIf.clone();
    }

    target.replace(lastBody);
    
    this.setChanged(method);
	}
}
