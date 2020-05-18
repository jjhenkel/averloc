package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class AddDeadCode extends AverlocTransformer {
  protected int UID = 0;

  public AddDeadCode(int uid) {
    this.UID = uid;
  }

	@Override
	public void transform(CtExecutable method) {
    Random rand = new Random();
    
    CtCodeSnippetStatement snippet = getFactory().Core().createCodeSnippetStatement();
    snippet.setValue(String.format(
      "if (false) { int REPLACEME%s = 1; }",
      Integer.toString(this.UID)
    ));

    if (rand.nextBoolean()) {
      method.getBody().insertBegin(snippet);
    } else {
      method.getBody().insertEnd(snippet);
    }
    
    this.setChanged(method);
	}
}
