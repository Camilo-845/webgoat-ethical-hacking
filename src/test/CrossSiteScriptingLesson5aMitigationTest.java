package org.owasp.webgoat.lessons.xss;

import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.not;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.owasp.webgoat.container.plugins.LessonTest;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

class CrossSiteScriptingLesson5aMitigationTest extends LessonTest {

  @Test
  void reflectedValueIsHtmlEscaped() throws Exception {
    mockMvc
        .perform(
            MockMvcRequestBuilders.get("/CrossSiteScripting/attack5a")
                .param("QTY1", "1")
                .param("QTY2", "0")
                .param("QTY3", "0")
                .param("QTY4", "0")
                .param("field1", "<script>alert(1)</script>")
                .param("field2", "safe"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.output", containsString("&lt;script&gt;")))
        .andExpect(jsonPath("$.output", not(containsString("<script>alert(1)</script>"))));
  }
}
