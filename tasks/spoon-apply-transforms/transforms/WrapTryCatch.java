package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class WrapTryCatch extends AverlocTransformer {
  protected int UID = 0;

  public WrapTryCatch(int uid) {
    this.UID = uid;
  }

	@Override
	public void transform(CtExecutable method) {
    ArrayList<CtLiteral> literals = getChildrenOfType(
      method, CtLiteral.class
    );

    CtTry wrapper = getFactory().Core().createTry();

    wrapper.addCatcher(
      getFactory().Code().createCtCatch(
        "REPLACEME" + Integer.toString(this.UID),
        java.lang.Exception.class,
        getFactory().Code().createCtBlock(
          getFactory().Code().createCtThrow(
            "REPLACEME" + Integer.toString(this.UID)
          )
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
