package transforms;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class InsertPrintStatements extends AverlocTransformer {
  // Parameters to this renaming transform
  final static int MIN_INSERTIONS = 1;
  final static int MAX_INSERTIONS = 3;
  final static int LITERAL_MIN_LENGTH = 1;
  final static int LITERAL_MAX_LENGTH = 5;

	@Override
	public void transform(CtExecutable method) {
    Random rand = new Random();

    int numInsertions = rand.nextInt(
      (MAX_INSERTIONS - MIN_INSERTIONS) + 1
    ) + MIN_INSERTIONS;

    for (int i = 0; i < numInsertions; i++) {
      int literalLength = rand.nextInt(
        (LITERAL_MAX_LENGTH - LITERAL_MIN_LENGTH) + 1
      ) + LITERAL_MIN_LENGTH;

      Collections.shuffle(topTargetSubtokens);

      String literal = camelCased(
        topTargetSubtokens.subList(0, literalLength)
      );

      CtCodeSnippetStatement snippet = getFactory().Core().createCodeSnippetStatement();
      snippet.setValue(String.format("System.out.println(\"%s\")", literal));

      // Insert randomly begin/end
      if (rand.nextBoolean()) {
        method.getBody().insertBegin(snippet);
      } else {
        method.getBody().insertEnd(snippet);
      }
      
      this.setChanged(method);
    }
	}
}
