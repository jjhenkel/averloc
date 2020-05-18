package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class InsertPrintStatements extends AverlocTransformer {
  protected int UID = 0;

  public InsertPrintStatements(int uid) {
    this.UID = uid;
  }

	@Override
	public void transform(CtExecutable method) {
    Random rand = new Random();
    
    CtCodeSnippetStatement snippet = getFactory().Core().createCodeSnippetStatement();
    snippet.setValue(String.format(
      "System.out.println(\"REPLACEME%s\")",
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
