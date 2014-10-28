#include <stdio.h>
#include <assert.h>

// File generated by --header switch inside the nimcache directory.
#include "test_c_api.h"

const char *valid_rst_filename = "temp_good.rst";
const char *bad_rst_filename = "temp_bad.rst";

char valid_rst_string[] = "Embedded *rst* text";
char bad_rst_string[] = "Asterisks and Obelix\n"
	"====================\n"
	"\n"
	"These asterisks* are bad for rst.\n"
	"\n"
	"* Not that we really care.\n"
	"\n"
	// The underscore will be replaced at runtime!
	"Or was <B it _single quotes?";

// Helper to write a null terminated string to a specific path.
void overwrite(const char *filename, const char *s)
{
	assert(filename && *filename);
	assert(s);
	FILE *file = fopen(filename, "w+");
	assert(file);
	fwrite(s, 1, strlen(s), file);
	fclose(file);
}

// Entry point of the C test.
void run_c_test(char *error_rst, char *special_options)
{
	// Due to backticks being escaped in Nimrod's emit pragma (see
	// https://github.com/Araq/Nimrod/issues/1588) we have to modify
	// bad_rst_string at runtime to avoid it being escaped during Nimrod's C
	// codegen phase.
	assert(strchr(bad_rst_string, '_'));
	*strchr(bad_rst_string, '_') = 0x60;

	// Generates files with rst content.
	{
		overwrite(valid_rst_filename, valid_rst_string);
		overwrite(bad_rst_filename, bad_rst_string);
	}

	printf("Using lazy_rest %s.\n", lr_version_str());

	int major = 6, minor = 6, maintenance = 6;
	lr_version_int(&major, &minor, &maintenance);
	printf("Using lazy_rest: %d-%d-%d.\n",
		major, minor, maintenance);

	// Tests unsafe string conversions.
	{
		char *s = lr_rst_string_to_html(valid_rst_string,
			"<string>", 0);
		assert(0 != s);
		if (s) {
			// Success!
			assert(strstr(s, "<title>"));
			overwrite("temp_string_to_html.html", s);
		} else {
			// Handle error.
		}
	}

	{
		char *s = lr_rst_string_to_html(bad_rst_string,
			"<bad-string>", 0);
		assert(0 == s);
		if (!s) {
			// Handle error.
			printf("1 Ignore the next error message, it's expected\n");
			printf("Error processing string: %s\n",
				lr_rst_string_to_html_error());
		}
	}

	// Tests unsafe file conversions.
	{
		char *s = lr_rst_file_to_html(valid_rst_filename, 0);
		assert(0 != s);
		if (s) {
			// Success!
			overwrite("temp_file_to_html.html", s);
		} else {
			// Handle error.
		}
	}

	{
		char *s = lr_rst_file_to_html(bad_rst_filename, 0);
		assert(0 == s);
		if (!s) {
			// Handle error.
			printf("2 Ignore the next error message, it's expected\n");
			printf("Error processing file: %s\n",
				lr_rst_file_to_html_error());
		}
	}

	// Test the safe string conversions.
	{
		char *s = lr_safe_rst_string_to_html(
			"<filename>", valid_rst_string, 0, 0);
		overwrite("temp_safe_string_1.html", s);
		assert(s);
		assert(strstr(s, "<title>"));
		int errors = 1;
		s = lr_safe_rst_string_to_html(
			"<filename>", valid_rst_string, &errors, 0);
		assert(0 == errors);
		overwrite("temp_safe_string_2.html", s);
		if (s) {
			// Success!
		} else {
			// Handle error.
		}
	}

	{
		char *s = lr_safe_rst_string_to_html(
			"<filename>", bad_rst_string, 0, 0);
		assert(s);
		assert(strstr(s, "<title>"));
		overwrite("temp_safe_string_3.html", s);
		int errors = 0;
		s = lr_safe_rst_string_to_html(
			"<filename>", bad_rst_string, &errors, 0);
		assert(errors > 0);
		overwrite("temp_safe_string_4.html", s);
		if (errors) {
			// Handle error.
			printf("3 Ignore the next error message, it's expected\n");
			printf("RST error stack trace:\n");
			while (errors) {
				printf("\t%s\n",
					lr_safe_rst_string_to_html_error(--errors));
			}
		}
	}

	// Test the safe file conversions.
	{
		char *s = lr_safe_rst_file_to_html(
			valid_rst_filename, 0, 0);
		overwrite("temp_safe_file_1.html", s);
		assert(s);
		assert(strstr(s, "<title>"));
		int errors = 1;
		s = lr_safe_rst_file_to_html(
			valid_rst_filename, &errors, 0);
		assert(0 == errors);
		overwrite("temp_safe_file_2.html", s);
		if (s) {
			// Success!
		} else {
			// Handle error.
		}
	}

	{
		char *s = lr_safe_rst_file_to_html(
			bad_rst_filename, 0, 0);
		assert(s);
		assert(strstr(s, "<title>"));
		overwrite("temp_safe_file_3.html", s);
		int errors = 0;
		s = lr_safe_rst_file_to_html(
			bad_rst_filename, &errors, 0);
		assert(errors > 0);
		overwrite("temp_safe_file_4.html", s);
		if (errors) {
			// Handle error.
			printf("4 Ignore the next error message, it's expected\n");
			printf("RST error stack trace:\n");
			while (errors) {
				printf("\t%s\n",
					lr_safe_rst_file_to_html_error(--errors));
			}
		}
	}

	// Tests the nim file conversion.
	{
		char *s = lr_nim_file_to_html("test_c_api.nim", 1, 0);
		overwrite("temp_nim_file_1.html", s);
		s = lr_nim_file_to_html("test_c_api.nim", 0, 0);
		overwrite("temp_nim_file_2.html", s);
	}

	// Test normal error rst.
	{
		if (lr_set_normal_error_rst(error_rst)) {
			// Handle error.
			assert(0);
		} else {
			assert(1);
			char *s = lr_safe_rst_file_to_html(
				bad_rst_filename, 0, 0);
			assert(s);
			assert(strstr(s, "<title>"));
			overwrite("temp_set_error_template_1.html", s);
		}

		int errors = lr_set_normal_error_rst(bad_rst_string);
		assert(errors);
		if (errors) {
			printf("5 Ignore the next error messages\n");
			printf("Could not set normal error rst!\n");
			while (errors) {
				printf("\t%s\n",
					lr_set_normal_error_rst_error(--errors));
			}
		}
	}

	// Test option override.
	{
		int did_change = lr_set_global_rst_options(special_options);
		assert(did_change && "Did fail changing global options?");

		char *s = lr_safe_rst_file_to_html(
			bad_rst_filename, 0, 0);
		overwrite("temp_global_options_1.html", s);
		s = lr_safe_rst_file_to_html(
			valid_rst_filename, 0, 0);
		overwrite("temp_global_options_2.html", s);

		// Reset back to nil.
		did_change = lr_set_global_rst_options(0);
		assert(!did_change);
		s = lr_safe_rst_file_to_html(
			valid_rst_filename, 0, 0);
		overwrite("temp_global_options_3.html", s);
	}
}
