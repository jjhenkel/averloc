package transforms;

import spoon.processing.AbstractProcessor;
import spoon.reflect.code.CtCodeSnippetStatement;
import spoon.reflect.declaration.CtClass;
import spoon.reflect.declaration.CtExecutable;

public class AddDeadCode extends AverlocTransformer {

	@Override
	public void transform(CtExecutable method) {
		CtCodeSnippetStatement snippet = getFactory().Core().createCodeSnippetStatement();

		// Snippet which contains the log.
		final String value = "if (false) { int counterStepHexDigest = 1; }";

		snippet.setValue(value);

		// Inserts the snippet at the beginning of the method body.
		if (method.getBody() != null) {
			method.getBody().insertBegin(snippet);
		}
	}
}
