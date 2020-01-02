package transforms;

import spoon.processing.AbstractProcessor;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import spoon.reflect.visitor.CtIterator;


public class RenameLocalVariable extends AbstractProcessor<CtExecutable> {

	@Override
	public void process(CtExecutable element) {
		if (element.getSimpleName() == "<init>") {
			return;
		}

		CtCodeSnippetStatement snippet = getFactory().Core().createCodeSnippetStatement();

        CtIterator iterator1 = new CtIterator(element);

        while (iterator1.hasNext()) {
            CtElement el = iterator1.next();

            if (el instanceof CtLocalVariable) {
                System.out.println(((CtLocalVariable)el).getSimpleName());
            }
        }

        CtIterator iterator2 = new CtIterator(element);

        while (iterator2.hasNext()) {
            CtElement el = iterator2.next();

            if (el instanceof CtVariableAccess) {
                CtVariableReference<?> theVariable = ((CtVariableAccess)el).getVariable();
                if (theVariable != null) {
                    CtNamedElement theDecl = theVariable.getDeclaration();
                    if (theDecl != null) {
                        System.out.println(theDecl.getSimpleName());
                    }
                }
            }
        }

	}
}
