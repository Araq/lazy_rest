// Source file taken from https://github.com/gradha/OpenIrekia-Android/blob/02ba3c73a27a8055b8dcc87ecaaf96c2532a9984/src/net/efaber/irekia/Formatter.java
//
// OpenIrekia v2.0 Cliente Android
//
// Copyright 2009-2011 eFaber, S.L.
// Copyright 2009-2011 Ejie, S.A.
// Copyrigth 2009-2011 Dirección de Gobierno Abierto y Comunicación en Internet; 
//    Gobernu Irekirako eta Interneteko Komunikaziorako Zuzendaritza; Lehendakaritza.
//    Gobierno Vasco – Eusko Jaurlaritza 
// Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas 
// por la Comisión Europea– versiones posteriores de la EUPL (la Licencia);
// Solo podrá usarse esta obra si se respeta la Licencia. Puede obtenerse una 
// copia de la Licencia en: http://ec.europa.eu/idabc/eupl 
// Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
// el programa distribuido con arreglo a la Licencia se distribuye TAL CUAL,
// SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
// Véase la Licencia en el idioma concreto que rige los permisos y limitaciones 
// que establece la Licencia
//
//  http://open.irekia.net, openirekia@efaber.net

package net.efaber.irekia;

import static junit.framework.Assert.assertTrue;
import android.text.Layout;
import android.text.StaticLayout;
import android.text.TextPaint;

/** Wrapper around StaticLayout to perform proper ellipsis.
 * The default StaticLayout class doesn't work with ellipsis and line limits,
 * so we have to do our own here. We first create a StaticLayout, and if it
 * goes out of the number of lines, the last one is reformatted to fit with an
 * ellipsis.
 */
public class Formatter
{
private String last_text;
private int last_max_width;
private int last_max_lines;
private StaticLayout last_layout;

/** Resets the internal cache.
 * You can also use this to free memory if needed.
 */
public void reset()
{
	last_text = null;
	last_layout = null;
	last_max_width = last_max_lines = -1;
}

/** Public interface to construct the layout.
 * Pass the parameters to generate the StaticLayout. This function will memoize
 * the results if the input parameters have not changed since the last call.
 * Note that from all the input parameters the value of paint is ignored. If
 * you need to force a change for the paint, call reset().
 *
 * @return Returns the StaticLayout object you should use to draw the
 * reformatted text.
 */
public StaticLayout build(final String text, final TextPaint paint,
	final int max_width, final int max_lines)
{
	assertTrue("Need a valid text", null != text);
	assertTrue("Need a valid paint", null != paint);
	assertTrue("max_lines needs to be positive", max_lines > 0);
	assertTrue("max_width has to be positive", max_width > 0);

	if (null != last_text && last_text.equals(text) &&
			last_max_width == max_width &&
			last_max_lines == max_lines) {

		return last_layout;
	}

	last_text = text;
	last_max_width = max_width;
	last_max_lines = max_lines;
	last_layout = internal_build(text, paint, max_width, max_lines);
	return last_layout;
}

/** Does the real work of building the formatted version text.
 * Pass the long string of text that has to be formatted, the paint it has to
 * be painted with, the maximum width of the text, and the maximum number of
 * lines that can be generated.
 *
 * The function will first create a temporary StaticLayout with all the lines.
 * If it fits the requirements, it will be returned directly. If this can't be
 * accomplished, a second iterative version is run where the last line is
 * progressively cut out of characters replaced by an ellipsis.
 *
 * @return Returns the new StaticLayout to use.
 */
private StaticLayout internal_build(final String text, final TextPaint paint,
	final int max_width, final int max_lines)
{
	assertTrue("Need a valid text", null != text);
	assertTrue("Need a valid paint", null != paint);
	assertTrue("max_lines needs to be positive", max_lines > 0);
	assertTrue("max_width has to be positive", max_width > 0);

	StaticLayout l = new StaticLayout(text, paint, max_width,
		Layout.Alignment.ALIGN_NORMAL, 1f, 0f, false);
	if (max_lines >= l.getLineCount())
		return l;

	// Ok, we are overflowing. Get the last valid char and trim text.
	final int first_char = l.getLineStart(max_lines - 1);
	//final last_char = Math.max(0, l.getLineEnd(max_lines - 1) - 3);
	final int last_char = l.getLineEnd(max_lines - 1);
	final String trailing_line;

	if (last_char - first_char < 1) {
		trailing_line = "…";
	} else {
		String temp = text.substring(first_char, last_char).trim() + "…";
		int f = 3;
		while (f > 0 && temp.length() > 1) {
			final int width = (int)paint.measureText(temp);
			if (width < max_width) {
				break;
			} else {
				temp = temp.substring(0, temp.length() - 2) + "…";
				f--;
			}
		}
		trailing_line = temp;
	}
	return new StaticLayout(text.substring(0, first_char) + trailing_line,
		paint, max_width, Layout.Alignment.ALIGN_NORMAL, 1f, 0f, false);
}

}
