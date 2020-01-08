package transforms;

import spoon.processing.AbstractProcessor;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import spoon.reflect.visitor.CtIterator;

import java.util.*;
import java.util.stream.*;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.io.IOException;
import java.lang.Math;

public class AverlocTransformer extends AbstractProcessor<CtExecutable> {
  
  final static int TARGET_SUBTOKENS_LIMIT = 100;
  static ArrayList<String> TOP_N_TARGET_SUBTOKENS;

  static
  {
      // Load the top tokens once
      try (Stream<String> lines = Files.lines(Paths.get("/histo.txt"))) {
        TOP_N_TARGET_SUBTOKENS = new ArrayList<String>(
              lines.limit(TARGET_SUBTOKENS_LIMIT).collect(Collectors.toList())
          );
      } catch (IOException ex) { }
  }

  protected <T extends CtElement> ArrayList<T> getChildrenOfType(CtExecutable method, Class<T> baseCls) {
    ArrayList<T> results = new ArrayList<T>();
    CtIterator iter = new CtIterator(method);
    while (iter.hasNext()) {
        CtElement el = iter.next();
        if (baseCls.isInstance(el)) {
          results.add((T)el);
        }
    }
    return results;
  }

  // Build a camel cased name from a randomized sub-token list
  protected String camelCased(List<String> inputs) {
      String retVal = inputs.get(0);
      for (String part : inputs.subList(1, inputs.size())) {
          retVal += part.substring(0, 1).toUpperCase() + part.substring(1);
      }
      return retVal;
  }

	@Override
	public void process(CtExecutable element) {
    // Skip this 
    if (element.getSimpleName().equals("<init>")) {
      return;
    }
    
    // Also skip nested things...
    if (!((CtTypeMember)element).getDeclaringType().getSimpleName().equals("WRAPPER")) {
      return;
    }

    transform(element);
  }
  
  protected void transform(CtExecutable method) {

  }
}
