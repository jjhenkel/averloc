package transforms;

import spoon.processing.AbstractProcessor;
import spoon.reflect.code.CtCodeSnippetStatement;
import spoon.reflect.declaration.CtClass;
import spoon.reflect.declaration.CtExecutable;

public class AddDeadCodeAtBeginning extends AbstractProcessor<CtExecutable> {

	@Override
	public void process(CtExecutable element) {
		if (element.getSimpleName() == "<init>") {
			return;
		}

		CtCodeSnippetStatement snippet = getFactory().Core().createCodeSnippetStatement();

		// Snippet which contains the log.
		final String value = "if (false) { int counterStepHexDigest = 1; }";

		snippet.setValue(value);

		// Inserts the snippet at the beginning of the method body.
		if (element.getBody() != null) {
			element.getBody().insertBegin(snippet);
		}
	}
}
