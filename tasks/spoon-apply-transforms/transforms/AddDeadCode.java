package transforms;

import java.util.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import java.util.*;
import java.lang.Math;

public class AddDeadCode extends AverlocTransformer {
  protected int MIN_INSERTIONS = 2;
  protected int MAX_INSERTIONS = 6;
  protected int LITERAL_MIN_LENGTH = 2;
  protected int LITERAL_MAX_LENGTH = 7;

  public AddDeadCode(int minInsertions, int maxInsertions, int litearlMinLength, int literalMaxLength, ArrayList<String> topTargetSubtokens) {
    this.MIN_INSERTIONS = minInsertions;
    this.MAX_INSERTIONS = maxInsertions;
    this.LITERAL_MIN_LENGTH = litearlMinLength;
    this.LITERAL_MAX_LENGTH = literalMaxLength;
    this.setTopTargetSubtokens((ArrayList<String>)topTargetSubtokens.clone());
  }

	@Override
	public void transform(CtExecutable method) {
    Random rand = new Random();

    int numInsertions = rand.nextInt(
      (MAX_INSERTIONS - MIN_INSERTIONS) + 1
    ) + MIN_INSERTIONS;

    for (int i = 0; i < numInsertions; i++) {
      // int literalLength = rand.nextInt(
      //   (LITERAL_MAX_LENGTH - LITERAL_MIN_LENGTH) + 1
      // ) + LITERAL_MIN_LENGTH;

      // Collections.shuffle(topTargetSubtokens);

      // String literal = camelCased(
      //   topTargetSubtokens.subList(0, literalLength)
      // );

      CtCodeSnippetStatement snippet = getFactory().Core().createCodeSnippetStatement();
      snippet.setValue(String.format("if (false) { int REPLAC_ME_ADC_%s = 1; }", Integer.toString(i+1)));

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
